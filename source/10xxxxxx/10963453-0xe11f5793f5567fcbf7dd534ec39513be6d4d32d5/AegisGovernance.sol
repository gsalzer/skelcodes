pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./EIP20Interface.sol";
import "./EIP20NonStandardInterface.sol";

/**
 * @notice AegisGovernance
 * @author Aegis
 */
contract AegisGovernance {
    string public constant name = "Aegis Governor";
    function passVotes() public pure returns (uint) {return 500000e8;}
    function passMantissa() public pure returns (uint) {return 0.3e8;}
    function proposalThreshold() public pure returns (uint) { return 150000e8; } // 0.5% of AGS
    function proposalMaxOperations() public pure returns (uint) { return 10; }
    function votingDelay() public pure returns (uint) { return 1; }
    function votingPeriod() public pure returns (uint) { return 17280; }

    TimelockInterface public timelock;
    address public guardian;
    uint public proposalCount;
    mapping (uint => Proposal) public proposals;
    mapping (address => uint) public latestProposalIds;
    mapping(address => mapping(uint => uint)) public checkPointVotes;
    mapping(address => uint) public checkPointProposal;

    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    event ProposalCreated(uint _id, address _proposer, address[] _targets, uint[] _values, string[] _signatures, bytes[] _calldatas, uint _startBlock, uint _endBlock, string _description);
    event VoteCast(address _voter, uint _proposalId, bool _support, uint _votes);
    event ProposalCanceled(uint _id);
    event ProposalQueued(uint _id, uint _eta);
    event ProposalExecuted(uint _id);
    event VotesLockup(address _account, uint _number, uint _lockup);
    event ProposeLockup(address _account, uint _number, uint _lockup);
    event ProposeFreed(address _account, uint _number, uint _remaining);
    event VotesFreed(address _account, uint _number, uint _remaining);

    struct Proposal {
        uint id;
        address proposer;
        uint eta;
        address[] targets;
        uint[] values;
        string[] signatures;
        bytes[] calldatas;
        uint startBlock;
        uint endBlock;
        uint forVotes;
        uint againstVotes;
        bool canceled;
        bool executed;
        mapping (address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    constructor(address _timelock, address _guardian) public {
        timelock = TimelockInterface(_timelock);
        guardian = _guardian;
    }

    function proposeLockup(uint _number) public {
        require(_number > 0, "AegisGovernance::proposeLockup number must be greater than 0");
        uint actualAmount = doTransferIn(msg.sender, _number);
        uint old = checkPointProposal[msg.sender];
        checkPointProposal[msg.sender] = old + actualAmount;
        emit ProposeLockup(msg.sender, _number, checkPointProposal[msg.sender]);
    }

    function proposeFreed(address payable _account, uint _proposalId) public {
        require(state(_proposalId) != ProposalState.Active, "AegisGovernance::proposeFreed voting is not closed");
        Proposal storage proposal = proposals[_proposalId];
        require(_account == msg.sender && _account == proposal.proposer, "AegisGovernance::proposeFreed no permission to operate");
        require(checkPointProposal[_account] > 0, "AegisGovernance::proposeFreed insufficient coins");
        uint number = checkPointProposal[_account];
        doTransferOut(_account, number);
        checkPointProposal[_account] = 0;
        emit ProposeFreed(_account, number, checkPointProposal[_account]);
    }

    function votesLockup(uint _number, uint _proposalId) public {
        require(_number > 0, "AegisGovernance::votesLockup number must be greater than 0");
        require(state(_proposalId) == ProposalState.Active, "AegisGovernance::votesLockup voting is closed");
        uint actualAmount = doTransferIn(msg.sender, _number);
        uint old = checkPointVotes[msg.sender][_proposalId];
        checkPointVotes[msg.sender][_proposalId] = old + actualAmount;
        emit VotesLockup(msg.sender, _number, getPriorVotes(msg.sender, _proposalId));
    }

    function votesFreed(address payable _account, uint _proposalId) public {
        require(state(_proposalId) != ProposalState.Active, "AegisGovernance::votesFreed voting is not closed");
        require(msg.sender == _account, "AegisGovernance::votesFreed no permission to operate");
        uint number = checkPointVotes[_account][_proposalId];
        doTransferOut(_account, number);
        checkPointVotes[_account][_proposalId] = 0;
        emit VotesFreed(_account, number, checkPointVotes[_account][_proposalId]);
    }

    function getPriorVotes(address _account, uint _proposalId) public view returns (uint) {
        return checkPointVotes[_account][_proposalId];
    }

    function totalLockUp() public view returns (uint) {
        return EIP20Interface(underlying()).balanceOf(address(this));
    }

    function propose(address[] memory _targets, uint[] memory _values, string[] memory _signatures, bytes[] memory _calldatas, string memory _description) public returns (uint) {
        require(checkPointProposal[msg.sender] >= proposalThreshold(), "AegisGovernance::propose: proposer votes below proposal threshold");
        require(_targets.length == _values.length && _targets.length == _signatures.length && _targets.length == _calldatas.length, "AegisGovernance::propose: proposal function information arity mismatch");
        require(_targets.length != 0, "AegisGovernance::propose: must provide actions");
        require(_targets.length <= proposalMaxOperations(), "AegisGovernance::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "AegisGovernance::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "AegisGovernance::propose: one live proposal per proposer, found an already pending proposal");
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: _targets,
            values: _values,
            signatures: _signatures,
            calldatas: _calldatas,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(newProposal.id, msg.sender, _targets, _values, _signatures, _calldatas, startBlock, endBlock, _description);
        return newProposal.id;
    }

    function queue(uint _proposalId) public {
        require(state(_proposalId) == ProposalState.Succeeded, "AegisGovernance::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[_proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(_proposalId, eta);
    }

    function _queueOrRevert(address _target, uint _value, string memory _signature, bytes memory _data, uint _eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(_target, _value, _signature, _data, _eta))), "AegisGovernance::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(_target, _value, _signature, _data, _eta);
    }

    function execute(uint _proposalId) public payable {
        require(state(_proposalId) == ProposalState.Queued, "AegisGovernance::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[_proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(_proposalId);
    }

    function cancel(uint _proposalId) public {
        ProposalState state = state(_proposalId);
        require(state != ProposalState.Executed, "AegisGovernance::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == guardian || checkPointProposal[proposal.proposer] < proposalThreshold(), "AegisGovernance::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(_proposalId);
    }

    function getActions(uint _proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint _proposalId, address _voter) public view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    function state(uint _proposalId) public view returns (ProposalState) {
        require(proposalCount >= _proposalId && _proposalId > 0, "AegisGovernance::state: invalid proposal id");
        Proposal storage proposal = proposals[_proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes * passMantissa() / 1e8 <= proposal.againstVotes || proposal.forVotes + proposal.againstVotes < passVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint _proposalId, bool _support) public {
        require(getPriorVotes(msg.sender, _proposalId) > 0, "AegisGovernance::castVote not enough votes");
        return _castVote(msg.sender, _proposalId, _support);
    }

    function castVoteBySig(uint _proposalId, bool _support, uint8 _v, bytes32 _r, bytes32 _s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, _proposalId, _support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, _v, _r, _s);
        require(signatory != address(0), "AegisGovernance::castVoteBySig: invalid signature");
        return _castVote(signatory, _proposalId, _support);
    }

    function _castVote(address _voter, uint _proposalId, bool _support) internal {
        require(state(_proposalId) == ProposalState.Active, "AegisGovernance::_castVote: voting is closed");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];
        require(receipt.hasVoted == false, "AegisGovernance::_castVote: voter already voted");
        uint votes = getPriorVotes(_voter, _proposalId);

        if (_support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    function doTransferIn(address from, uint amount) internal returns (uint) {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying());
        uint balanceBefore = EIP20Interface(underlying()).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    success := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        require(success, "LOCKUP::TOKEN_TRANSFER_IN_FAILED");
        
        uint balanceAfter = EIP20Interface(underlying()).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "TOKEN_TRANSFER_IN_OVERFLOW");
        return balanceAfter - balanceBefore;
    }

    function doTransferOut(address payable to, uint amount) internal {
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying());
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
                case 0 {
                    success := not(0)
                }
                case 32 {
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
                default {
                    revert(0, 0)
                }
        }
        require(success, "LOCKUP::TOKEN_TRANSFER_OUT_FAILED");
    }

    function underlying() internal pure returns (address) {
        return address(0xdB2F2bCCe3efa95EDA95a233aF45F3e0d4f00e2A);
    }

    function __acceptAdmin() public {
        require(msg.sender == guardian, "AegisGovernance::__acceptAdmin: sender must be gov guardian");
        timelock.acceptAdmin();
    }

    function __abdicate() public {
        require(msg.sender == guardian, "AegisGovernance::__abdicate: sender must be gov guardian");
        guardian = address(0);
    }

    function __queueSetTimelockPendingAdmin(address _newPendingAdmin, uint _eta) public {
        require(msg.sender == guardian, "AegisGovernance::__queueSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.queueTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(_newPendingAdmin), _eta);
    }

    function __executeSetTimelockPendingAdmin(address _newPendingAdmin, uint _eta) public {
        require(msg.sender == guardian, "AegisGovernance::__executeSetTimelockPendingAdmin: sender must be gov guardian");
        timelock.executeTransaction(address(timelock), 0, "setPendingAdmin(address)", abi.encode(_newPendingAdmin), _eta);
    }

    function add256(uint256 _a, uint256 _b) internal pure returns (uint) {
        uint c = _a + _b;
        require(c >= _a, "addition overflow");
        return c;
    }

    function sub256(uint256 _a, uint256 _b) internal pure returns (uint) {
        require(_b <= _a, "subtraction underflow");
        return _a - _b;
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}
