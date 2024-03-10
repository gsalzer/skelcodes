/*
 * SPDX-License-Identifier:    GPL-3.0
 */

pragma solidity 0.6.8;
pragma experimental ABIEncoderV2; // required for passing structs in calldata (fairly secure at this point)

import "erc3k/contracts/IERC3000.sol";

import "@aragon/govern-contract-utils/contracts/acl/ACL.sol";
import "@aragon/govern-contract-utils/contracts/adaptive-erc165/AdaptiveERC165.sol";
import "@aragon/govern-contract-utils/contracts/deposits/DepositLib.sol";
import "@aragon/govern-contract-utils/contracts/erc20/SafeERC20.sol";
import '@aragon/govern-contract-utils/contracts/safe-math/SafeMath.sol';

import "../protocol/IArbitrable.sol";
import "../protocol/IArbitrator.sol";

library GovernQueueStateLib {
    enum State {
        None,
        Scheduled,
        Challenged,
        Approved,
        Rejected,
        Cancelled,
        Executed
    }

    struct Item {
        State state;
    }

    function checkState(Item storage _item, State _requiredState) internal view {
        require(_item.state == _requiredState, "queue: bad state");
    }

    function setState(Item storage _item, State _state) internal {
        _item.state = _state;
    }

    function checkAndSetState(Item storage _item, State _fromState, State _toState) internal {
        checkState(_item, _fromState);
        setState(_item, _toState);
    }
}

contract GovernQueue is IERC3000, IArbitrable, AdaptiveERC165, ACL {
    // Syntax sugar to enable method-calling syntax on types
    using ERC3000Data for *;
    using DepositLib for ERC3000Data.Collateral;
    using GovernQueueStateLib for GovernQueueStateLib.Item;
    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    // Map '4' as the 'allow' ruling; this implicitly maps '3' as the 'reject' ruling
    uint256 internal constant ALLOW_RULING = 4;

    // Permanent state
    bytes32 public configHash; // keccak256 hash of the current ERC3000Data.Config
    uint256 public nonce; // number of scheduled payloads so far
    mapping (bytes32 => GovernQueueStateLib.Item) public queue; // container hash -> execution state

    // Temporary state
    mapping (bytes32 => address) public challengerCache; // container hash -> challenger addr (used after challenging and before dispute resolution)
    mapping (bytes32 => mapping (IArbitrator => uint256)) public disputeItemCache; // container hash -> arbitrator addr -> dispute id (used between dispute creation and ruling)

    /**
     * @param _aclRoot account that will be given root permissions on ACL (commonly given to factory)
     * @param _initialConfig initial configuration parameters
     */
    constructor(address _aclRoot, ERC3000Data.Config memory _initialConfig)
        public
        ACL(_aclRoot) // note that this contract directly derives from ACL (ACL is local to contract and not global to system in Govern)
    {
        initialize(_aclRoot, _initialConfig);
    }

    function initialize(address _aclRoot, ERC3000Data.Config memory _initialConfig) public initACL(_aclRoot) onlyInit("queue") {
        _setConfig(_initialConfig);
        _registerStandard(type(IERC3000).interfaceId);
    }

     /**
     * @notice Schedules an action for execution, allowing for challenges and vetos on a defined time window. Pulls collateral from submitter into contract.
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     */
    function schedule(ERC3000Data.Container memory _container) // TO FIX: Container is in memory and function has to be public to avoid an unestrutable solidity crash
        public
        override
        auth(this.schedule.selector) // note that all functions in this contract are ACL protected (commonly some of them will be open for any addr to perform)
        returns (bytes32 containerHash)
    {
        // prevent griefing by front-running (the same container is sent by two different people and one must be challenged)
        // and ensure container hashes are unique
        require(_container.payload.nonce == ++nonce, "queue: bad nonce");
        // hash using ERC3000Data.hash(ERC3000Data.Config)
        bytes32 _configHash = _container.config.hash();
        // ensure that the hash of the config passed in the container matches the current config (implicit agreement approval by scheduler)
        require(_configHash == configHash, "queue: bad config");
        // ensure that the time delta to the execution timestamp provided in the payload is at least after the config's execution delay
        require(_container.payload.executionTime >= _container.config.executionDelay.add(block.timestamp), "queue: bad delay");
        // ensure that the submitter of the payload is also the sender of this call
        require(_container.payload.submitter == msg.sender, "queue: bad submitter");
        // Restrict the size of calldata to _container.config.maxCalldataSize to make sure challenge function stays callable
        uint calldataSize;
        assembly {
            calldataSize := calldatasize()
        }
        require(calldataSize <= _container.config.maxCalldataSize, "calldatasize: limit exceeded");
        // store and set container's hash
        containerHash = ERC3000Data.containerHash(_container.payload.hash(), _configHash);
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.None, // ensure that the state for this container is None
            GovernQueueStateLib.State.Scheduled // and if so perform a state transition to Scheduled
        );
        // we don't need to save any more state about the container in storage
        // we just authenticate the hash and assign it a state, since all future
        // actions regarding the container will need to provide it as a witness
        // all witnesses are logged from this contract at least once, so the
        // trust assumption should be the same as storing all on-chain (move complexity to clients)

        ERC3000Data.Collateral memory collateral = _container.config.scheduleDeposit;
        collateral.collectFrom(_container.payload.submitter); // pull collateral from submitter (requires previous approval)

        // the configured resolver may specify additional out-of-band payments for scheduling actions
        // schedule() leaves these requirements up to the callers of `schedule()` or other users to fulfill

        // emit an event to ensure data availability of all state that cannot be otherwise fetched (see how config isn't emitted since an observer should already have it)
        emit Scheduled(containerHash, _container.payload);
    }

    /**
     * @notice Executes an action after its execution delay has passed and its state hasn't been altered by a challenge or veto
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     */
    function execute(ERC3000Data.Container memory _container)
        public
        override
        auth(this.execute.selector) // in most instances this will be open for any addr, but leaving configurable for flexibility
        returns (bytes32 failureMap, bytes[] memory)
    {
        // ensure enough time has passed
        require(block.timestamp >= _container.payload.executionTime, "queue: wait more");

        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled, // note that we will revert here if the container wasn't previously scheduled
            GovernQueueStateLib.State.Executed
        );

        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter); // release collateral to original submitter

        return _execute(_container.payload, containerHash);
    }

    /**
     * @notice Challenge a container in case its scheduling is illegal as per Config.rules. Pulls collateral and dispute fees from sender into contract
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param _reason Hint for case reviewers as to why the scheduled container is illegal
     */
    function challenge(ERC3000Data.Container memory _container, bytes memory _reason) auth(this.challenge.selector) override public returns (uint256 disputeId) {
        bytes32 containerHash = _container.hash();
        challengerCache[containerHash] = msg.sender; // cache challenger address while it is needed
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Scheduled,
            GovernQueueStateLib.State.Challenged
        );

        ERC3000Data.Collateral memory collateral = _container.config.challengeDeposit;
        collateral.collectFrom(msg.sender); // pull challenge collateral from sender

        // create dispute on arbitrator
        IArbitrator arbitrator = IArbitrator(_container.config.resolver);
        (address recipient, ERC20 feeToken, uint256 feeAmount) = arbitrator.getDisputeFees();
        require(feeToken.safeTransferFrom(msg.sender, address(this), feeAmount), "queue: bad fee pull");
        require(feeToken.safeApprove(recipient, feeAmount), "queue: bad approve");
        disputeId = arbitrator.createDispute(2, abi.encode(_container)); // create dispute sending full container ABI encoded (could prob just send payload to save gas)
        require(feeToken.safeApprove(recipient, 0), "queue: bad reset"); // reset just in case non-compliant tokens (that fail on non-zero to non-zero approvals) are used

        // submit both arguments as evidence and close evidence period. no more evidence can be submitted and a settlement can't happen (could happen off-protocol)
        arbitrator.submitEvidence(disputeId, _container.payload.submitter, _container.payload.proof);
        arbitrator.submitEvidence(disputeId, msg.sender, _reason);
        arbitrator.closeEvidencePeriod(disputeId);

        disputeItemCache[containerHash][arbitrator] = disputeId + 1; // cache a relation between disputeId and containerHash while needed

        emit Challenged(containerHash, msg.sender, _reason, disputeId, collateral);
    }

    /**
     * @notice Apply arbitrator's ruling over a challenge once it has come to a final ruling
     * @param _container A ERC3000Data.Container struct holding both the payload being scheduled for execution and
     * the current configuration of the system
     * @param _disputeId disputeId in the arbitrator in which the dispute over the container was created
     */
    function resolve(ERC3000Data.Container memory _container, uint256 _disputeId) override public returns (bytes32 failureMap, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        IArbitrator arbitrator = IArbitrator(_container.config.resolver);

        require(disputeItemCache[containerHash][arbitrator] == _disputeId + 1, "queue: bad dispute id");
        delete disputeItemCache[containerHash][arbitrator]; // release state to refund gas; no longer needed in state

        queue[containerHash].checkState(GovernQueueStateLib.State.Challenged);
        (address subject, uint256 ruling) = arbitrator.rule(_disputeId);
        require(subject == address(this), "queue: not subject");
        bool arbitratorApproved = ruling == ALLOW_RULING;

        queue[containerHash].setState(
            arbitratorApproved
              ? GovernQueueStateLib.State.Approved
              : GovernQueueStateLib.State.Rejected
        );

        emit Resolved(containerHash, msg.sender, arbitratorApproved);
        emit Ruled(arbitrator, _disputeId, ruling);

        if (arbitratorApproved) {
            return _executeApproved(_container);
        } else {
            return _settleRejection(_container);
        }
    }

    function veto(ERC3000Data.Container memory _container, bytes memory _reason) auth(this.veto.selector) override public {
        bytes32 containerHash = _container.hash();
        GovernQueueStateLib.Item storage item = queue[containerHash];

        if (item.state == GovernQueueStateLib.State.Challenged) {
            item.checkAndSetState(
                GovernQueueStateLib.State.Challenged,
                GovernQueueStateLib.State.Cancelled
            );

            address challenger = challengerCache[containerHash];
            // release state to refund gas; no longer needed in state
            delete challengerCache[containerHash];
            delete disputeItemCache[containerHash][IArbitrator(_container.config.resolver)];

            // release collateral to challenger and scheduler
            _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
            _container.config.challengeDeposit.releaseTo(challenger);
        } else {
            // If the given container doesn't have the state Challenged
            // has it to be the Scheduled state and otherwise should it throw as expected
            item.checkAndSetState(
                GovernQueueStateLib.State.Scheduled,
                GovernQueueStateLib.State.Cancelled
            );

            _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
        }

        emit Vetoed(containerHash, msg.sender, _reason);
    }

    /**
     * @notice Apply a new configuration for all *new* containers to be scheduled
     * @param _config A ERC3000Data.Config struct holding all the new params that will control the queue
     */
    function configure(ERC3000Data.Config memory _config)
        public
        override
        auth(this.configure.selector)
        returns (bytes32)
    {
        return _setConfig(_config);
    }

    // Internal

    function _executeApproved(ERC3000Data.Container memory _container) internal returns (bytes32 failureMap, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Approved,
            GovernQueueStateLib.State.Executed
        );

        delete challengerCache[containerHash]; // release state to refund gas; no longer needed in state

        // release all collateral to submitter
        _container.config.scheduleDeposit.releaseTo(_container.payload.submitter);
        _container.config.challengeDeposit.releaseTo(_container.payload.submitter);

        return _execute(_container.payload, containerHash);
    }

    function _settleRejection(ERC3000Data.Container memory _container) internal returns (bytes32, bytes[] memory) {
        bytes32 containerHash = _container.hash();
        queue[containerHash].checkAndSetState(
            GovernQueueStateLib.State.Rejected,
            GovernQueueStateLib.State.Cancelled
        );

        address challenger = challengerCache[containerHash];
        delete challengerCache[containerHash]; // release state to refund gas; no longer needed in state

        // release all collateral to challenger
        _container.config.scheduleDeposit.releaseTo(challenger);
        _container.config.challengeDeposit.releaseTo(challenger);

        // return zero values as nothing is executed on rejection
    }

    function _execute(ERC3000Data.Payload memory _payload, bytes32 _containerHash) internal returns (bytes32, bytes[] memory) {
        emit Executed(_containerHash, msg.sender);
        return _payload.executor.exec(_payload.actions, _payload.allowFailuresMap, _containerHash);
    }

    function _setConfig(ERC3000Data.Config memory _config)
        internal
        returns (bytes32)
    {
        // validate collaterals by calling balanceOf on their interface
        if(_config.challengeDeposit.amount != 0 && _config.challengeDeposit.token != address(0)) {
            (bool ok, bytes memory value) = _config.challengeDeposit.token.call(
                abi.encodeWithSelector(ERC20.balanceOf.selector, address(this))
            );
            require(ok && value.length > 0, "queue: bad config");
        }

        if(_config.scheduleDeposit.amount != 0 && _config.scheduleDeposit.token != address(0)) {
            (bool ok, bytes memory value) = _config.scheduleDeposit.token.call(
                abi.encodeWithSelector(ERC20.balanceOf.selector, address(this))
            );
            require(ok && value.length > 0, "queue: bad config");
        }
        
        configHash = _config.hash();

        emit Configured(configHash, msg.sender, _config);

        return configHash;
    }
}

