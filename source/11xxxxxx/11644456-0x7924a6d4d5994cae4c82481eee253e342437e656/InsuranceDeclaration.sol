// SPDX-License-Identifier: --🦉--

pragma solidity ^0.8.0;

import './WiseTokenInterface.sol';

interface UniswapRouter {
    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
}

contract InsuranceDeclaration {

    WiseTokenInterface public immutable WISE_CONTRACT;
    UniswapRouter public immutable UNISWAP_ROUTER;

    address constant wiseToken =
    0x66a0f676479Cee1d7373f3DC2e2952778BfF5bd6;

    address constant uniswapRouter =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address public constant WETH =
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;


    // tracking state variables - cannot be changed by master
    uint256 public totalStaked; // - just to track amount of total tokens staked
    uint256 public totalCovers; // - amount of tokens we need to cover
    uint256 public totalBufferStaked;  // - to track amount of tokens dedicated to buffer stakes
    uint256 public totalPublicDebth;   // - amount of tokens we own to public contributors
    uint256 public totalPublicRewards; // - amount of token we allocate to public payouts (to public contribs)
    uint256 public totalMasterProfits; // - tracking profits for the master, to know how much can be taken

    uint256 public teamContribution; // initial funding from the team

    // threshold for opening new stakes - can be adjusted by master
    uint256 public coverageThreshold;

    // threshold for profit payouts - can be adjusted by master
    uint256 public payoutThreshold;

    // threshold for getting staked amount back - can be adjusted by master
    uint256 public penaltyThresholdA;
    uint256 public penaltyThresholdB;

    // threshold for getting staked amount back - can be adjusted by master
    uint256 public penaltyA;
    uint256 public penaltyB;

    // % amount to be staked when opening insurance stake - can be adjusted by master
    uint256 public stakePercent;

    // % amount to return from principal when closing stake - can be adjusted by master
    uint256 public principalCut; // (0%-10%)

    // % amount to return from interest when closing stake - can be adjusted by master
    uint256 public interestCut; // (0%-10%)

    // % amount to return for public investor - can be adjusted by master
    uint256 public publicRewardPercent;

    // cap for public contributions
    uint256 public publicDebthCap;

    // cap for buffer staking total amount - can be adjusted by master
    uint256 public bufferStakeCap;

    // ability to control maximum buffer stake duration - can be adjusted by master
    uint256 public maximumBufferStakeDuration;

    // ability to purchase insurancce - can be switched by master
    bool public allowInsurance;

    // ability to fund treasury from outside - can be switched by master
    bool public allowPublicContributions;

    // ability to reroute buffer stake interest as developer funds - can be switched by master
    bool public getBufferStakeInterest;

    uint256 constant MAX_STAKE_DAYS = 1095; // constant cannot be adjusted 3 years

    address payable public insuranceMaster; // master is a MultiSigWallet
    address payable public insuranceWorker; // worker can be defined by master

    struct InsuranceStake {
        bytes16 stakeID;
        uint256 bufferAmount;
        uint256 stakedAmount;
        uint256 matureAmount;
        uint256 emergencyAmount;
        address currentOwner;
        bool isActive;
    }

    struct BufferStake {
        uint256 stakedAmount;
        bytes16 stakeID;
        bool isActive;
    }

    struct OwnerlessStake {
        uint256 stakeIndex;
        address originalOwner;
    }

    uint256 public bufferStakeCount;
    uint256 public ownerlessStakeCount;
    uint256 public insuranceStakeCount;

    uint256 public activeInsuranceStakeCount;
    uint256 public activeOwnerlessStakeCount;
    uint256 public activeBufferStakeCount;

    mapping (address => uint256) public insuranceStakeCounts;
    mapping (address => mapping(uint256 => InsuranceStake)) public insuranceStakes;

    mapping (uint256 => BufferStake) public bufferStakes;
    mapping (uint256 => OwnerlessStake) public ownerlessStakes;

    // tracking individual public debth to contributor
    mapping (address => uint256) public publicReward;

    modifier onlyMaster() {
        require(
            msg.sender == insuranceMaster,
            'WiseInsurance: not an agent'
        );
        _;
    }

    modifier onlyWorker() {
        require(
            msg.sender == insuranceWorker,
            'WiseInsurance: not a worker'
        );
        _;
    }

    event TreasuryFunded(
        uint256 amount,
        address funder,
        uint256 total
    );

    event InsurancStakeOpened(
        bytes16 indexed stakeID,
        uint256 stakedAmount,
        uint256 returnAmount,
        address indexed originalOwner,
        uint256 indexed stakeIndex,
        bytes16 referralID
    );

    event EmergencyExitStake(
        address indexed stakeOwner,
        uint256 indexed stakeIndex,
        bytes16 indexed stakeID,
        uint256 returnAfterFee,
        uint256 returnAmount,
        uint64 currentWiseDay
    );

    event NewOwnerlessStake(
        uint256 indexed ownerlessIndex,
        uint256 indexed stakeIndex,
        address indexed stakeOwner
    );

    event InsuranceStakeClosed(
        address indexed staker,
        uint256 indexed stakeIndex,
        bytes16 indexed stakeID,
        uint256 returnAmount,
        uint256 rewardAfterFee
    );

    event OwnerlessStakeClosed(
        uint256 ownerlessIndex,
        address indexed staker,
        uint256 indexed stakeIndex,
        bytes16 indexed stakeID,
        uint256 stakedAmount,
        uint256 rewardAmount
    );

    event BufferStakeOpened(
        bytes16 indexed stakeID,
        uint256 stakedAmount,
        bytes16 indexed referralID
    );

    event BufferStakeClosed(
        bytes16 indexed stakeID,
        uint256 stakedAmount,
        uint256 rewardAmount
    );

    event PublicContributionsOpened(
        bool indexed status
    );

    event PublicProfit(
        address indexed contributor,
        uint256 amount,
        uint256 publicDebth,
        uint256 publicRewards
    );

    event ProfitsTaken(
        uint256 profitAmount,
        uint256 remainingBuffer
    );

    event publicRewardsGiven(
        uint256 rewardAmount,
        uint256 totalPublicDebth,
        uint256 totalPublicRewards
    );

    event DeveloperFundsRouted(
        uint256 fundsAmount
    );

    event checkStake(
        uint256 startDay,
        uint256 lockDays,
        uint256 finalDay,
        uint256 closeDay,
        uint256 scrapeDay,
        uint256 stakedAmount,
        uint256 stakesShares,
        uint256 rewardAmount,
        uint256 penaltyAmount,
        bool isActive,
        bool isMature
    );

    constructor() {

        WISE_CONTRACT = WiseTokenInterface(
            wiseToken
        );

        UNISWAP_ROUTER = UniswapRouter(
            uniswapRouter
        );

        stakePercent = 90;
        payoutThreshold = 10;
        coverageThreshold = 3;

        penaltyThresholdA = 0;
        penaltyThresholdB = 0;

        penaltyA = 0;
        penaltyB = 0;

        insuranceMaster = payable(0xfEc4264F728C056bD528E9e012cf4D943bd92b53);
        insuranceWorker = payable(0x9404f4B0846A2cD5c659c1edD52BA60abF1F10F4);

        allowInsurance = true;
    }

    address ZERO_ADDRESS = address(0x0);

    string TRANSFER_FAILED = 'WiseInsurance: transfer failed';

    string NOT_YOUR_STAKE = 'WiseInsurance: stake ownership already renounced';
    string NOT_MATURE_STAKE = 'WiseInsurance: stake is not mature';
    string NOT_ACTIVE_STAKE = 'WiseInsurance: stake already closed';
    string NOT_OWNERLESS_STAKE = 'WiseInsurance: stake is not ownerless';

    string MATURED_STAKE = 'WiseInsurance: stake already matured';
    string BELOW_COVERAGE_THRESHOLD = 'WiseInsurance: below coverage threshold';
    string BELOW_PAYOUT_THRESHOLD = 'WiseInsurance: below payout threshold';
    string PUBLIC_CONTRIBUTIONS_DISABLED = 'WiseInsurance: public contributions closed';
    string DECREASE_STAKE_DURATION = 'WiseInsurance: lockDays exceeded';
    string INSURANCE_DISABLED = 'WiseInsurance: disabled';
    string NO_REWARD_FOR_CONTRIBUTOR = 'WiseInsurance: no rewards for contributor';
    string NO_PUBLIC_DEBTH = 'WiseInsurance: no public debth';
    string NO_PUBLIC_REWARD_AVAILABLE = 'WiseInsurance: no rewards in public pot';
    string EXCEEDING_PUBLIC_DEBTH_CAP = 'WiseInsurance: exceeding public debth cap';
    string PUBLIC_DEBTH_NOT_PAID = 'WiseInsurance: public debth not paid';
    string PUBLIC_CONTRIBUTION_MUST_BE_DISABLED = 'WiseInsurance: public contributions must be disabled';
}
