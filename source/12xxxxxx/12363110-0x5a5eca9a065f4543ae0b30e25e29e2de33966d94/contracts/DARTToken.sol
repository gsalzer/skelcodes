// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/Context.sol";

import "./LiquidityTrap/LiquidityTrap.sol";
import "./LiquidityTrap/LiquidityActivityTrap.sol";

contract DARTToken is Context, LiquidityTrap, LiquidityActivityTrap {
    string public constant NAME = "dART Token";
    string public constant SYMBOL = "dART";
    uint8 public constant DECIMALS = 18;
    uint256 public constant TOTAL_SUPPLY = 142090000 * (10**uint256(DECIMALS));

    address public SeedInvestmentAddr;
    address public PrivateSaleAddr;
    address public StakingRewardsAddr;
    address public LiquidityPoolAddr;
    address public MarketingAddr;
    address public TreasuryAddr;
    address public TeamAllocationAddr;
    address public AdvisorsAddr;
    address public ReserveAddr;

    uint256 public constant SEED_INVESTMENT = 3000000 * (10**uint256(DECIMALS)); // 2.1% for Seed investment
    uint256 public constant PRIVATE_SALE = 15000000 * (10**uint256(DECIMALS)); // 10.6% for Private Sale

    uint256 public constant STAKING_REWARDS = 24500000 * (10**uint256(DECIMALS)); // 17.2% for Staking rewards
    
    uint256 public constant LIQUIDITY_POOL = 9000000 * (10**uint256(DECIMALS)); // 6.3% for Liquidity pool

    uint256 public constant MARKETING = 14000000 * (10**uint256(DECIMALS)); // 9.9% for Marketing/Listings
    uint256 public constant TREASURY = 19600000 * (10**uint256(DECIMALS)); // 13.8% for Treasury

    uint256 public constant TEAM_ALLOCATION = 17000000 * (10**uint256(DECIMALS)); // 12% for Team allocation
    uint256 public constant ADVISORS = 5000000 * (10**uint256(DECIMALS)); // 3.5% for Advisors

    uint256 public constant RESERVE = 34990000 * (10**uint256(DECIMALS)); // 24.6% for Bridge consumption

    bool private _isDistributionComplete = false;
    bool public protected = true;

    constructor(uint128 _trapAmount, address _uniswapV2Factory, address _pairToken) 
        ERC20(NAME, SYMBOL)
        LiquidityProtectedBase(_uniswapV2Factory, _pairToken)
        LiquidityTrap(_trapAmount)
    {
        _mint(address(this), TOTAL_SUPPLY);
    }

    function setDistributionTeamsAddresses(
        address _SeedInvestmentAddr,
        address _PrivateSaleAddr,
        address _StakingRewardsAddr,
        address _LiquidityPoolAddr,
        address _MarketingAddr,
        address _TreasuryAddr,
        address _TeamAllocationAddr,
        address _AdvisorsAddr,
        address _ReserveAddr
    ) external onlyOwner {
        require(!_isDistributionComplete, "Already distributed");

        // set parnters addresses
        SeedInvestmentAddr = _SeedInvestmentAddr;
        PrivateSaleAddr = _PrivateSaleAddr;
        StakingRewardsAddr = _StakingRewardsAddr;
        LiquidityPoolAddr = _LiquidityPoolAddr;
        MarketingAddr = _MarketingAddr;
        TreasuryAddr = _TreasuryAddr;
        TeamAllocationAddr = _TeamAllocationAddr;
        AdvisorsAddr = _AdvisorsAddr;
        ReserveAddr = _ReserveAddr;
    }

    function distributeTokens() external onlyOwner {
        require(!_isDistributionComplete, "Already distributed");

        _transfer(address(this), SeedInvestmentAddr, SEED_INVESTMENT);
        _transfer(address(this), PrivateSaleAddr, PRIVATE_SALE);
        _transfer(address(this), StakingRewardsAddr, STAKING_REWARDS);
        _transfer(address(this), LiquidityPoolAddr, LIQUIDITY_POOL);
        _transfer(address(this), MarketingAddr, MARKETING);
        _transfer(address(this), TreasuryAddr, TREASURY);
        _transfer(address(this), TeamAllocationAddr, TEAM_ALLOCATION);
        _transfer(address(this), AdvisorsAddr, ADVISORS);
        _transfer(address(this), ReserveAddr, RESERVE);

        _isDistributionComplete = true;
    }

    function disableProtection() external onlyOwner {
        protected = false;
    }

    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        if (protected) {
            LiquidityActivityTrap_validateTransfer(_from, _to, _amount);
            LiquidityTrap_validateTransfer(_from, _to, _amount);
        }
    }
}

