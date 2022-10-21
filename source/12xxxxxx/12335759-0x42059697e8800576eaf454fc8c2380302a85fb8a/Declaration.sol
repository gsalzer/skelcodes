// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

import "./Global.sol";

abstract contract Declaration is Global {

    uint256 constant _decimals = 18;
    uint256 constant REI_PER_GRISE = 10 ** _decimals; // 1 GRISE = 1E18 REI
    
    uint64 constant PRECISION_RATE = 1E18;
    uint32 constant REWARD_PRECISION_RATE = 1E4;

    uint16 constant GRISE_WEEK = 7;
    uint16 constant GRISE_MONTH = GRISE_WEEK * 4;
    uint16 constant GRISE_YEAR = GRISE_MONTH * 12;

    // Inflation Reward
    uint32 constant INFLATION_RATE = 57658685; // per day Inflation Amount
    uint16 constant MED_TERM_INFLATION_REWARD = 3000; // 30% of Inflation Amount with 1E4 Precision
    uint16 constant LONG_TERM_INFLATION_REWARD = 7000; // 70% of Inflation Amount with 1E4 Precision

    uint16 constant ST_STAKER_COMPENSATION = 200; // 2.00% multiple 1E4 Precision
    uint16 constant MLT_STAKER_COMPENSATION = 347; // 3.47% multiple 1E4 Precision

    // End-Stake Panalty Reward
    uint16 constant PENALTY_RATE = 1700; // pre-mature end-stake penalty
    uint16 constant RESERVOIR_PENALTY_REWARD = 3427;
    uint16 constant SHORT_STAKER_PENALTY_REWARD = 1311;
    uint16 constant MED_LONG_STAKER_PENALTY_REWARD = 2562;
    uint16 constant TEAM_PENALTY_REWARD = 1350;
    uint16 constant DEVELOPER_PENALTY_REWARD = 150;
    uint16 constant BURN_PENALTY_REWARD = 1200;

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // mainnet

    address constant TEAM_ADDRESS = 0xa377433831E83C7a4Fa10fB75C33217cD7CABec2;
    address constant DEVELOPER_ADDRESS = 0xcD8DcbA8e4791B19719934886A8bA77EA3fad447;

    IUniswapRouterV2 public constant UNISWAP_ROUTER = IUniswapRouterV2(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // mainnet
    );

    IGriseToken public GRISE_CONTRACT;
    address public contractDeployer;

    constructor(address _immutableAddress) 
    {
        contractDeployer = msg.sender;

        GRISE_CONTRACT = IGriseToken(_immutableAddress);

        // Min-Max Staking Day limit
        stakeDayLimit[StakeType.SHORT_TERM].minStakeDay = 1 * GRISE_WEEK;   // Min 1 Week
        stakeDayLimit[StakeType.SHORT_TERM].maxStakeDay = 12 * GRISE_WEEK;  // Max 12 Week
        stakeDayLimit[StakeType.MEDIUM_TERM].minStakeDay = 3 * GRISE_MONTH; // Min 3 Month
        stakeDayLimit[StakeType.MEDIUM_TERM].maxStakeDay = 9 * GRISE_MONTH; // Max 9 Month
        stakeDayLimit[StakeType.LONG_TERM].minStakeDay =  1 * GRISE_YEAR;  // Min 1 Year
        stakeDayLimit[StakeType.LONG_TERM].maxStakeDay = 10 * GRISE_YEAR;  // Max 10 Year

        //Min Staking Amount limit
        stakeCaps[StakeType.SHORT_TERM][0].minStakingAmount = 50 * REI_PER_GRISE;   // 50 GRISE TOKEN
        stakeCaps[StakeType.MEDIUM_TERM][0].minStakingAmount = 225 * REI_PER_GRISE; // 225 GIRSE TOKEN
        stakeCaps[StakeType.MEDIUM_TERM][1].minStakingAmount = 100 * REI_PER_GRISE; // 100 GIRSE TOKEN
        stakeCaps[StakeType.MEDIUM_TERM][2].minStakingAmount = 150 * REI_PER_GRISE; // 150 GIRSE TOKEN
        stakeCaps[StakeType.LONG_TERM][0].minStakingAmount = 100 * REI_PER_GRISE;  // 100 GIRSE TOKEN

        //Max Staking Slot Limit
        stakeCaps[StakeType.SHORT_TERM][0].maxStakingSlot = 1250;   // Max 1250 Slot Available
        stakeCaps[StakeType.MEDIUM_TERM][0].maxStakingSlot = 250;   // Max 250 Slot Available
        stakeCaps[StakeType.MEDIUM_TERM][1].maxStakingSlot = 500;   // Max 500 Slot Available
        stakeCaps[StakeType.MEDIUM_TERM][2].maxStakingSlot = 300;   // Max 300 Slot Available
        stakeCaps[StakeType.LONG_TERM][0].maxStakingSlot = 300;    // Max 300 Slot Available
    }

    struct Stake {
        uint256 stakesShares;
        uint256 stakedAmount;
        uint256 rewardAmount;
        StakeType stakeType;
        uint256 totalOccupiedSlot;
        uint256 startDay;
        uint256 lockDays;
        uint256 finalDay;
        uint256 closeDay;
        uint256 scrapeDay;
        bool isActive;
    }

    enum StakeType {
        SHORT_TERM,
        MEDIUM_TERM,
        LONG_TERM
    }

    struct StakeCapping {
        uint256 minStakingAmount;
        uint256 stakingSlotCount;
        uint256 maxStakingSlot;
        uint256 totalStakeCount;
    }

    struct StakeMinMaxDay{
        uint256 minStakeDay;
        uint256 maxStakeDay;
    }

    mapping(address => uint256) public stakeCount;
    mapping(address => mapping(bytes16 => uint256)) public scrapes;
    mapping(address => mapping(bytes16 => Stake)) public stakes;

    mapping(uint256 => uint256) public scheduledToEnd;
    mapping(uint256 => uint256) public totalPenalties;
    mapping(uint256 => uint256) public MLTPenaltiesRewardPerShares; // Medium/Long Term Penatly Reward
    mapping(uint256 => uint256) public STPenaltiesRewardPerShares;  // Short Term Penatly Reward
    mapping(uint256 => uint256) public ReservoirPenaltiesRewardPerShares;  // Short Term Penatly Reward

    mapping(StakeType => StakeMinMaxDay) public stakeDayLimit;
    mapping(StakeType => mapping(uint8 => StakeCapping)) public stakeCaps;
}

