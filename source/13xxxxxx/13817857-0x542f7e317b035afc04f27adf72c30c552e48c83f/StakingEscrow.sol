// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.0;


import "IERC900History.sol";
import "NuCypherToken.sol";
import "Bits.sol";
import "Snapshot.sol";
import "Upgradeable.sol";
import "Math.sol";
import "SafeERC20.sol";


/**
* @notice WorkLock interface
*/
interface WorkLockInterface {
    function token() external view returns (NuCypherToken);
}


/**
* @title StakingEscrowStub
* @notice Stub is used to deploy main StakingEscrow after all other contract and make some variables immutable
* @dev |v1.1.0|
*/
contract StakingEscrowStub is Upgradeable {
    NuCypherToken public immutable token;
    // only to deploy WorkLock
    uint32 public immutable secondsPerPeriod = 1;
    uint16 public immutable minLockedPeriods = 0;
    uint256 public immutable minAllowableLockedTokens;
    uint256 public immutable maxAllowableLockedTokens;

    /**
    * @notice Predefines some variables for use when deploying other contracts
    * @param _token Token contract
    * @param _minAllowableLockedTokens Min amount of tokens that can be locked
    * @param _maxAllowableLockedTokens Max amount of tokens that can be locked
    */
    constructor(
        NuCypherToken _token,
        uint256 _minAllowableLockedTokens,
        uint256 _maxAllowableLockedTokens
    ) {
        require(_token.totalSupply() > 0 &&
            _maxAllowableLockedTokens != 0);

        token = _token;
        minAllowableLockedTokens = _minAllowableLockedTokens;
        maxAllowableLockedTokens = _maxAllowableLockedTokens;
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);

        // we have to use real values even though this is a stub
        require(address(delegateGet(_testTarget, this.token.selector)) == address(token));
    }
}


/**
* @title StakingEscrow
* @notice Contract holds and locks stakers tokens.
* Each staker that locks their tokens will receive some compensation
* @dev |v6.1.1|
*/
contract StakingEscrow is Upgradeable, IERC900History {

    using Bits for uint256;
    using SafeMath for uint256;
    using Snapshot for uint128[];
    using SafeERC20 for NuCypherToken;

    /**
    * @notice Signals that tokens were deposited
    * @param staker Staker address
    * @param value Amount deposited (in NuNits)
    */
    event Deposited(address indexed staker, uint256 value);

    /**
    * @notice Signals that NU tokens were withdrawn to the staker
    * @param staker Staker address
    * @param value Amount withdraws (in NuNits)
    */
    event Withdrawn(address indexed staker, uint256 value);

    /**
    * @notice Signals that the staker was slashed
    * @param staker Staker address
    * @param penalty Slashing penalty
    * @param investigator Investigator address
    * @param reward Value of reward provided to investigator (in NuNits)
    */
    event Slashed(address indexed staker, uint256 penalty, address indexed investigator, uint256 reward);

    struct SubStakeInfo {
        uint16 firstPeriod;
        uint16 lastPeriod;
        uint16 unlockingDuration;
        uint128 lockedValue;
    }

    struct Downtime {
        uint16 startPeriod;
        uint16 endPeriod;
    }

    struct StakerInfo {
        uint256 value;
        uint16 currentCommittedPeriod;
        uint16 nextCommittedPeriod;
        uint16 lastCommittedPeriod;
        uint16 stub1; // former slot for lockReStakeUntilPeriod
        uint256 completedWork;
        uint16 workerStartPeriod; // period when worker was bonded
        address worker;
        uint256 flags; // uint256 to acquire whole slot and minimize operations on it

        uint256 reservedSlot1;
        uint256 reservedSlot2;
        uint256 reservedSlot3;
        uint256 reservedSlot4;
        uint256 reservedSlot5;

        Downtime[] pastDowntime;
        SubStakeInfo[] subStakes;
        uint128[] history;

    }

    // indices for flags (0-4 were in use, skip it in future)
//    uint8 internal constant SNAPSHOTS_DISABLED_INDEX = 3;

    NuCypherToken public immutable token;
    WorkLockInterface public immutable workLock;

    uint128 public previousPeriodSupply; // outdated
    uint128 public currentPeriodSupply; // outdated
    uint16 public currentMintingPeriod; // outdated

    mapping (address => StakerInfo) public stakerInfo;
    address[] public stakers;
    mapping (address => address) public stakerFromWorker;  // outdated

    mapping (uint16 => uint256) stub1; // former slot for lockedPerPeriod
    uint128[] public balanceHistory;  // outdated

    address stub2; // former slot for PolicyManager
    address stub3; // former slot for Adjudicator
    address stub4; // former slot for WorkLock

    mapping (uint16 => uint256) public lockedPerPeriod; // outdated

    /**
    * @notice Constructor sets address of token contract and parameters for staking
    * @param _token NuCypher token contract
    * @param _workLock WorkLock contract. Zero address if there is no WorkLock
    */
    constructor(
        NuCypherToken _token,
        WorkLockInterface _workLock
    ) {
        require(_token.totalSupply() > 0 &&
            (address(_workLock) == address(0) || _workLock.token() == _token),
            "Input addresses must be deployed contracts"
        );

        token = _token;
        workLock = _workLock;
    }

    /**
    * @dev Checks the existence of a staker in the contract
    */
    modifier onlyStaker()
    {
        require(stakerInfo[msg.sender].value > 0, "Caller must be a staker");
        _;
    }

    /**
    * @dev Checks caller is WorkLock contract
    */
    modifier onlyWorkLock()
    {
        require(msg.sender == address(workLock), "Caller must be the WorkLock contract");
        _;
    }

    //------------------------Main getters------------------------
    /**
    * @notice Get all tokens belonging to the staker
    */
    function getAllTokens(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].value;
    }

//    /**
//    * @notice Get all flags for the staker
//    */
//    function getFlags(address _staker)
//        external view returns (
//            bool snapshots
//        )
//    {
//        StakerInfo storage info = stakerInfo[_staker];
//        snapshots = !info.flags.bitSet(SNAPSHOTS_DISABLED_INDEX);
//    }

    /**
    * @notice Get work that completed by the staker
    */
    function getCompletedWork(address _staker) external view returns (uint256) {
        return token.totalSupply();
    }


    //------------------------Main methods------------------------
    /**
    * @notice Stub for WorkLock
    * @param _staker Staker
    * @param _measureWork Value for `measureWork` parameter
    * @return Work that was previously done
    */
    function setWorkMeasurement(address _staker, bool _measureWork)
        external onlyWorkLock returns (uint256)
    {
        return 0;
    }

    /**
    * @notice Deposit tokens from WorkLock contract
    * @param _staker Staker address
    * @param _value Amount of tokens to deposit
    * @param _unlockingDuration Amount of periods during which tokens will be unlocked when wind down is enabled
    */
    function depositFromWorkLock(
        address _staker,
        uint256 _value,
        uint16 _unlockingDuration
    )
        external onlyWorkLock
    {
        require(_value != 0, "Amount of tokens to deposit must be specified");
        StakerInfo storage info = stakerInfo[_staker];
        // initial stake of the staker
        if (info.value == 0 && info.lastCommittedPeriod == 0) {
            stakers.push(_staker);
        }
        token.safeTransferFrom(msg.sender, address(this), _value);
        info.value += _value;

        emit Deposited(_staker, _value);
    }

    //-------------------------Slashing-------------------------
    /**
    * @notice Slash the staker's stake and reward the investigator
    * @param _staker Staker's address
    * @param _penalty Penalty
    * @param _investigator Investigator
    * @param _reward Reward for the investigator
    */
    function slashStaker(
        address _staker,
        uint256 _penalty,
        address _investigator,
        uint256 _reward
    )
        internal
    {
        require(_penalty > 0, "Penalty must be specified");
        StakerInfo storage info = stakerInfo[_staker];
        if (info.value <= _penalty) {
            _penalty = info.value;
        }
        info.value -= _penalty;
        if (_reward > _penalty) {
            _reward = _penalty;
        }

        emit Slashed(_staker, _penalty, _investigator, _reward);
        if (_reward > 0) {
            token.safeTransfer(_investigator, _reward);
        }
    }

    //-------------Additional getters for stakers info-------------
    /**
    * @notice Return the length of the array of stakers
    */
    function getStakersLength() external view virtual returns (uint256) {
        return stakers.length;
    }

    /**
    * @notice Return the length of the array of sub stakes
    */
    function getSubStakesLength(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].subStakes.length;
    }

    /**
    * @notice Return the information about sub stake
    */
    function getSubStakeInfo(address _staker, uint256 _index)
    // TODO change to structure when ABIEncoderV2 is released (#1501)
//        public view returns (SubStakeInfo)
        // TODO "virtual" only for tests, probably will be removed after #1512
        external view virtual returns (
            uint16 firstPeriod,
            uint16 lastPeriod,
            uint16 unlockingDuration,
            uint128 lockedValue
        )
    {
        SubStakeInfo storage info = stakerInfo[_staker].subStakes[_index];
        firstPeriod = info.firstPeriod;
        lastPeriod = info.lastPeriod;
        unlockingDuration = info.unlockingDuration;
        lockedValue = info.lockedValue;
    }

    /**
    * @notice Return the length of the array of past downtime
    */
    function getPastDowntimeLength(address _staker) external view returns (uint256) {
        return stakerInfo[_staker].pastDowntime.length;
    }

    /**
    * @notice Return the information about past downtime
    */
    function  getPastDowntime(address _staker, uint256 _index)
    // TODO change to structure when ABIEncoderV2 is released (#1501)
//        public view returns (Downtime)
        external view returns (uint16 startPeriod, uint16 endPeriod)
    {
        Downtime storage downtime = stakerInfo[_staker].pastDowntime[_index];
        startPeriod = downtime.startPeriod;
        endPeriod = downtime.endPeriod;
    }

    //------------------ ERC900 connectors ----------------------

    function totalStakedForAt(address _owner, uint256 _blockNumber) public view override returns (uint256) {
        if (isUpgrade == UPGRADE_TRUE) {
            return stakerInfo[_owner].history.getValueAt(_blockNumber);
        }
        return 0;
    }

    function totalStakedAt(uint256 _blockNumber) public view override returns (uint256) {
        if (isUpgrade == UPGRADE_TRUE) {
            return balanceHistory.getValueAt(_blockNumber);
        }
        return token.totalSupply();
    }

    function supportsHistory() external pure override returns (bool) {
        return true;
    }

    //------------------------Upgradeable------------------------
    /**
    * @dev Get StakerInfo structure by delegatecall
    */
    function delegateGetStakerInfo(address _target, bytes32 _staker)
        internal returns (StakerInfo memory result)
    {
        bytes32 memoryAddress = delegateGetData(_target, this.stakerInfo.selector, 1, _staker, 0);
        assembly {
            result := memoryAddress
        }
    }

    /// @dev the `onlyWhileUpgrading` modifier works through a call to the parent `verifyState`
    function verifyState(address _testTarget) public override virtual {
        super.verifyState(_testTarget);

        require(delegateGet(_testTarget, this.getStakersLength.selector) == stakers.length);
        if (stakers.length == 0) {
            return;
        }
        address stakerAddress = stakers[0];
        require(address(uint160(delegateGet(_testTarget, this.stakers.selector, 0))) == stakerAddress);
        StakerInfo storage info = stakerInfo[stakerAddress];
        bytes32 staker = bytes32(uint256(stakerAddress));
        StakerInfo memory infoToCheck = delegateGetStakerInfo(_testTarget, staker);
        require(
            infoToCheck.value == info.value &&
            infoToCheck.flags == info.flags
        );
    }

}

