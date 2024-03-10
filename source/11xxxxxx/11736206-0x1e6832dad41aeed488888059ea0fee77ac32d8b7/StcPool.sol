// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Sts.sol";
import "./Stc.sol";
import "./ERC20.sol";
// import '.././TransferHelper.sol';
import "./UniswapPairOracle.sol";
import "./AccessControl.sol";
// import "./StringHelpers.sol";
import "./StcPoolLibrary.sol";

/*
   Same as StcPool.sol, but has some gas optimizations
*/


contract StcPool is AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    ERC20 private collateral_token;
    address private collateral_address;
    address private owner_address;
    // address private oracle_address;
    address private stc_contract_address;
    address private sts_contract_address;
    address private timelock_address; // Timelock address for the governance contract
    STCShares private STS;
    STCStablecoin private STC;
    // UniswapPairOracle private oracle;
    UniswapPairOracle private collatEthOracle;
    address public collat_eth_oracle_address;
    address private weth_address;
    address private fee_address;

    uint256 public minting_fee = 3000;
    uint256 public redemption_fee = 3000;
    uint256 public buyback_fee;
    uint256 public recollat_fee;

    mapping (address => uint256) public redeemSTSBalances;
    mapping (address => uint256) public redeemCollateralBalances;
    uint256 public unclaimedPoolCollateral;
    uint256 public unclaimedPoolSTS;
    mapping (address => uint256) public lastRedeemed;

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_PRECISION = 1e6;
    uint256 private constant COLLATERAL_RATIO_MAX = 1e6;

    // Number of decimals needed to get to 18
    uint256 private immutable missing_decimals;
    
    // Pool_ceiling is the total units of collateral that a pool contract can hold
    uint256 public pool_ceiling = 0;

    // Stores price of the collateral, if price is paused
    uint256 public pausedPrice = 0;

    // Bonus rate on STS minted during recollateralizeSTC(); 6 decimals of precision, set to 0.75% on genesis
    uint256 public bonus_rate = 7500;

    // Number of blocks to wait before being able to collectRedemption()
    uint256 public redemption_delay = 1;

    // AccessControl Roles
    bytes32 private constant MINT_PAUSER = keccak256("MINT_PAUSER");
    bytes32 private constant REDEEM_PAUSER = keccak256("REDEEM_PAUSER");
    bytes32 private constant BUYBACK_PAUSER = keccak256("BUYBACK_PAUSER");
    bytes32 private constant RECOLLATERALIZE_PAUSER = keccak256("RECOLLATERALIZE_PAUSER");
    bytes32 private constant COLLATERAL_PRICE_PAUSER = keccak256("COLLATERAL_PRICE_PAUSER");
    
    // AccessControl state variables
    bool public mintPaused = false;
    bool public redeemPaused = false;
    bool public recollateralizePaused = false;
    bool public buyBackPaused = false;
    bool public collateralPricePaused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == timelock_address || msg.sender == owner_address, "You are not the owner or the governance timelock");
        _;
    }

    modifier notRedeemPaused() {
        require(redeemPaused == false, "Redeeming is paused");
        _;
    }

    modifier notMintPaused() {
        require(mintPaused == false, "Minting is paused");
        _;
    }
 
    /* ========== CONSTRUCTOR ========== */
    
    constructor(
        address _stc_contract_address,
        address _sts_contract_address,
        address _collateral_address,
        address _creator_address,
        address _timelock_address,
        uint256 _pool_ceiling
    ) public {
        STC = STCStablecoin(_stc_contract_address);
        STS = STCShares(_sts_contract_address);
        stc_contract_address = _stc_contract_address;
        sts_contract_address = _sts_contract_address;
        collateral_address = _collateral_address;
        timelock_address = _timelock_address;
        owner_address = _creator_address;
        collateral_token = ERC20(_collateral_address);
        pool_ceiling = _pool_ceiling;
        missing_decimals = uint(18).sub(collateral_token.decimals());

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        grantRole(MINT_PAUSER, timelock_address);
        grantRole(REDEEM_PAUSER, timelock_address);
        grantRole(RECOLLATERALIZE_PAUSER, timelock_address);
        grantRole(BUYBACK_PAUSER, timelock_address);
        grantRole(COLLATERAL_PRICE_PAUSER, timelock_address);
    }

    /* ========== VIEWS ========== */

    // Returns dollar value of collateral held in this Stc pool
    function collatDollarBalance() public view returns (uint256) {
        if(collateralPricePaused == true){
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(pausedPrice).div(PRICE_PRECISION);
        } else {
            uint256 eth_usd_price = STC.eth_usd_price();
            uint256 eth_collat_price = collatEthOracle.consult(weth_address, (PRICE_PRECISION * (10 ** missing_decimals)));

            uint256 collat_usd_price = eth_usd_price.mul(PRICE_PRECISION).div(eth_collat_price);
            return (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)).mul(10 ** missing_decimals).mul(collat_usd_price).div(PRICE_PRECISION); //.mul(getCollateralPrice()).div(1e6);    
        }
    }

    // Returns the value of excess collateral held in this Stc pool, compared to what is needed to maintain the global collateral ratio
    function availableExcessCollatDV() public view returns (uint256) {
        uint256 total_supply = STC.totalSupply();
        uint256 global_collateral_ratio = STC.global_collateral_ratio();
        uint256 global_collat_value = STC.globalCollateralValue();

        if (global_collateral_ratio > COLLATERAL_RATIO_PRECISION) global_collateral_ratio = COLLATERAL_RATIO_PRECISION; // Handles an overcollateralized contract with CR > 1
        uint256 required_collat_dollar_value_d18 = (total_supply.mul(global_collateral_ratio)).div(COLLATERAL_RATIO_PRECISION); // Calculates collateral needed to back each 1 STC with $1 of collateral at current collat ratio
        if (global_collat_value > required_collat_dollar_value_d18) return global_collat_value.sub(required_collat_dollar_value_d18);
        else return 0;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // Returns the price of the pool collateral in USD
    function getCollateralPrice() public view returns (uint256) {
        if(collateralPricePaused == true){
            return pausedPrice;
        } else {
            uint256 eth_usd_price = STC.eth_usd_price();
            return eth_usd_price.mul(PRICE_PRECISION).div(collatEthOracle.consult(weth_address, PRICE_PRECISION * (10 ** missing_decimals)));
        }
    }

    function setFeeAddress(address _fee_address) external onlyByOwnerOrGovernance {
        fee_address = _fee_address;
    }

    function setCollatETHOracle(address _collateral_weth_oracle_address, address _weth_address) external onlyByOwnerOrGovernance {
        collat_eth_oracle_address = _collateral_weth_oracle_address;
        collatEthOracle = UniswapPairOracle(_collateral_weth_oracle_address);
        weth_address = _weth_address;
    }
  // We separate out the 1t1, fractional and algorithmic minting functions for gas efficiency 
    function mint1t1STC(uint256 collateral_amount, uint256 STC_out_min) external notMintPaused {
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 global_collateral_ratio = STC.global_collateral_ratio();

        require(global_collateral_ratio >= COLLATERAL_RATIO_MAX, "Collateral ratio must be >= 1");
        require((collateral_token.balanceOf(address(this))).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "[Pool's Closed]: Ceiling reached");
        
        (uint256 stc_amount_d18) = StcPoolLibrary.calcMint1t1STC(
            getCollateralPrice(),
            0,
            collateral_amount_d18
        ); //1 STC for each $1 worth of collateral

        require(STC_out_min <= stc_amount_d18, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        STC.pool_mint(fee_address, stc_amount_d18.mul(minting_fee).div(PRICE_PRECISION));
        STC.pool_mint(msg.sender, stc_amount_d18.sub(stc_amount_d18.mul(minting_fee).div(PRICE_PRECISION)));
    }

    function mintFractionalSTC(uint256 collateral_amount, uint256 sts_amount, uint256 STC_out_min) external notMintPaused {
        uint256 stc_price = STC.stc_price();
        uint256 sts_price = STC.sts_price();
        uint256 global_collateral_ratio = STC.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");
        require(collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral).add(collateral_amount) <= pool_ceiling, "Pool ceiling reached, no more STC can be minted with this collateral");

        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        StcPoolLibrary.MintFF_Params memory input_params = StcPoolLibrary.MintFF_Params(
            0, 
            sts_price,
            stc_price,
            getCollateralPrice(),
            sts_amount,
            collateral_amount_d18,
            (collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral)),
            pool_ceiling,
            global_collateral_ratio
        );

        (uint256 mint_amount, uint256 sts_needed) = StcPoolLibrary.calcMintFractionalSTC(input_params);

        require(STC_out_min <= mint_amount, "Slippage limit reached");
        require(sts_needed <= sts_amount, "Not enough STS inputted");
        STS.pool_burn_from(msg.sender, sts_needed);
        collateral_token.transferFrom(msg.sender, address(this), collateral_amount);
        STC.pool_mint(fee_address, mint_amount.mul(minting_fee).div(PRICE_PRECISION));
        STC.pool_mint(msg.sender, mint_amount.sub(mint_amount.mul(minting_fee).div(PRICE_PRECISION)));
    }

    // Redeem collateral. 100% collateral-backed
    function redeem1t1STC(uint256 STC_amount, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 global_collateral_ratio = STC.global_collateral_ratio();
        require(global_collateral_ratio == COLLATERAL_RATIO_MAX, "Collateral ratio must be == 1");
        uint256 STC_amount_precision = STC_amount.div(10 ** missing_decimals);
        (uint256 collateral_needed) = StcPoolLibrary.calcRedeem1t1STC(
            getCollateralPrice(),
            STC_amount_precision,
            0
        );
        require(collateral_needed <= collateral_token.balanceOf(address(this)), "Not enough collateral in pool");
        uint256 feeAmount = collateral_needed.mul(redemption_fee).div(PRICE_PRECISION);
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_needed.sub(feeAmount));
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_needed.sub(feeAmount));
        lastRedeemed[msg.sender] = block.number;
        require(COLLATERAL_out_min <= collateral_needed, "Slippage limit reached");
        STC.transferFrom(msg.sender, fee_address, STC_amount.mul(redemption_fee).div(PRICE_PRECISION));
        STC.pool_burn_from(msg.sender, STC_amount.sub(STC_amount.mul(redemption_fee).div(PRICE_PRECISION)));
    }

    // Will fail if fully collateralized or algorithmic
    // Redeem STC for collateral and STS. > 0% and < 100% collateral-backed
    function redeemFractionalSTC(uint256 STC_amount, uint256 STS_out_min, uint256 COLLATERAL_out_min) external notRedeemPaused {
        uint256 global_collateral_ratio = STC.global_collateral_ratio();

        require(global_collateral_ratio < COLLATERAL_RATIO_MAX && global_collateral_ratio > 0, "Collateral ratio needs to be between .000001 and .999999");

        uint256 STC_amount_post_fee = STC_amount.sub((STC_amount.mul(0)).div(PRICE_PRECISION));
        uint256 sts_amount = STC_amount_post_fee.sub(STC_amount_post_fee.mul(global_collateral_ratio).div(PRICE_PRECISION)).mul(PRICE_PRECISION).div(STC.sts_price());

        uint256 collateral_amount = STC_amount_post_fee.div(10 ** missing_decimals).mul(global_collateral_ratio).div(PRICE_PRECISION).mul(PRICE_PRECISION).div(getCollateralPrice());
        
        redeemCollateralBalances[msg.sender] = redeemCollateralBalances[msg.sender].add(collateral_amount.sub(collateral_amount.mul(redemption_fee).div(1e6)));
        unclaimedPoolCollateral = unclaimedPoolCollateral.add(collateral_amount.sub(collateral_amount.mul(redemption_fee).div(1e6)));

        redeemSTSBalances[msg.sender] = redeemSTSBalances[msg.sender].add(sts_amount.sub(sts_amount.mul(redemption_fee).div(1e6)));
        unclaimedPoolSTS = unclaimedPoolSTS.add(sts_amount.sub(sts_amount.mul(redemption_fee).div(1e6)));

        lastRedeemed[msg.sender] = block.number;

        require(collateral_amount <= collateral_token.balanceOf(address(this)).sub(unclaimedPoolCollateral), "Not enough collateral in pool");
        require(COLLATERAL_out_min <= collateral_amount && STS_out_min <= sts_amount, "Slippage limit reached");
        
        // Move all external functions to the end
        STC.transferFrom(msg.sender, fee_address, STC_amount.mul(redemption_fee).div(PRICE_PRECISION));
        STC.pool_burn_from(msg.sender, STC_amount.sub(STC_amount.mul(redemption_fee).div(PRICE_PRECISION)));
        STS.pool_mint(address(this), sts_amount.sub(sts_amount.mul(redemption_fee).div(PRICE_PRECISION)));
    }

    // After a redemption happens, transfer the newly minted STS and owed collateral from this pool
    // contract to the user. Redemption is split into two functions to prevent flash loans from being able
    // to take out STC/collateral from the system, use an AMM to trade the new price, and then mint back into the system.
    function collectRedemption() external {
        require((lastRedeemed[msg.sender].add(redemption_delay)) <= block.number, "Must wait for redemption_delay blocks before collecting redemption");
        bool sendSTS = false;
        bool sendCollateral = false;
        uint STSAmount;
        uint CollateralAmount;

        // Use Checks-Effects-Interactions pattern
        if(redeemSTSBalances[msg.sender] > 0){
            STSAmount = redeemSTSBalances[msg.sender];
            redeemSTSBalances[msg.sender] = 0;
            unclaimedPoolSTS = unclaimedPoolSTS.sub(STSAmount);

            sendSTS = true;
        }
        
        if(redeemCollateralBalances[msg.sender] > 0){
            CollateralAmount = redeemCollateralBalances[msg.sender];
            redeemCollateralBalances[msg.sender] = 0;
            unclaimedPoolCollateral = unclaimedPoolCollateral.sub(CollateralAmount);

            sendCollateral = true;
        }

        if(sendSTS == true){
            STS.transfer(msg.sender, STSAmount);
        }
        if(sendCollateral == true){
            collateral_token.transfer(msg.sender, CollateralAmount);
        }
        emit CollectRedemption(msg.sender, CollateralAmount);
    }


    // When the protocol is recollateralizing, we need to give a discount of STS to hit the new CR target
    // Thus, if the target collateral ratio is higher than the actual value of collateral, minters get STS for adding collateral
    // This function simply rewards anyone that sends collateral to a pool with the same amount of STS + the bonus rate
    // Anyone can call this function to recollateralize the protocol and take the extra STS value from the bonus rate as an arb opportunity
    function recollateralizeSTC(uint256 collateral_amount, uint256 STS_out_min) external {
        require(recollateralizePaused == false, "Recollateralize is paused");
        uint256 collateral_amount_d18 = collateral_amount * (10 ** missing_decimals);
        uint256 sts_price = STC.sts_price();
        uint256 stc_total_supply = STC.totalSupply();
        uint256 global_collateral_ratio = STC.global_collateral_ratio();
        uint256 global_collat_value = STC.globalCollateralValue();

        (uint256 collateral_units, uint256 amount_to_recollat) = StcPoolLibrary.calcRecollateralizeSTCInner(
            collateral_amount_d18,
            getCollateralPrice(),
            global_collat_value,
            stc_total_supply,
            global_collateral_ratio
        ); 

        uint256 collateral_units_precision = collateral_units.div(10 ** missing_decimals);

        uint256 sts_paid_back = amount_to_recollat.mul(uint(1e6).add(bonus_rate).sub(recollat_fee)).div(sts_price);

        require(STS_out_min <= sts_paid_back, "Slippage limit reached");
        collateral_token.transferFrom(msg.sender, address(this), collateral_units_precision);
        STS.pool_mint(msg.sender, sts_paid_back);
        emit RecollateralizeSTC(msg.sender, collateral_units_precision);
        
    }

    // Function can be called by an STS holder to have the protocol buy back STS with excess collateral value from a desired collateral pool
    // This can also happen if the collateral ratio > 1
    function buyBackSTS(uint256 STS_amount, uint256 COLLATERAL_out_min) external {
        require(buyBackPaused == false, "Buyback is paused");
        uint256 sts_price = STC.sts_price();
    
        StcPoolLibrary.BuybackSTS_Params memory input_params = StcPoolLibrary.BuybackSTS_Params(
            availableExcessCollatDV(),
            sts_price,
            getCollateralPrice(),
            STS_amount
        );

        (uint256 collateral_equivalent_d18) = (StcPoolLibrary.calcBuyBackSTS(input_params)).mul(uint(1e6).sub(buyback_fee)).div(1e6);
        uint256 collateral_precision = collateral_equivalent_d18.div(10 ** missing_decimals);

        require(COLLATERAL_out_min <= collateral_precision, "Slippage limit reached");
        // Give the sender their desired collateral and burn the STS
        STS.pool_burn_from(msg.sender, STS_amount);
        collateral_token.transfer(msg.sender, collateral_precision);
        emit Buyback(msg.sender, collateral_precision);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function toggleMinting() external onlyByOwnerOrGovernance {
        mintPaused = !mintPaused;
    }

    function toggleRedeeming() external onlyByOwnerOrGovernance {
        redeemPaused = !redeemPaused;
    }

    function toggleRecollateralize() external onlyByOwnerOrGovernance {
        recollateralizePaused = !recollateralizePaused;
    }
    
    function toggleBuyBack() external onlyByOwnerOrGovernance {
        buyBackPaused = !buyBackPaused;
    }

    function toggleCollateralPrice(uint256 _new_price) external {
        require(hasRole(COLLATERAL_PRICE_PAUSER, msg.sender));
        // If pausing, set paused price; else if unpausing, clear pausedPrice
        if(collateralPricePaused == false){
            pausedPrice = _new_price;
        } else {
            pausedPrice = 0;
        }
        collateralPricePaused = !collateralPricePaused;
    }

    // Combined into one function due to 24KiB contract memory limit
    function setPoolParameters(uint256 new_ceiling, uint256 new_bonus_rate, uint256 new_redemption_delay, uint256 new_mint_fee, uint256 new_redeem_fee, uint256 new_buyback_fee, uint256 new_recollat_fee) external onlyByOwnerOrGovernance {
        pool_ceiling = new_ceiling;
        bonus_rate = new_bonus_rate;
        redemption_delay = new_redemption_delay;
        minting_fee = new_mint_fee;
        redemption_fee = new_redeem_fee;
        buyback_fee = new_buyback_fee;
        recollat_fee = new_recollat_fee;
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    /* ========== EVENTS ========== */
    event MintSTC(address indexed mint_user,uint256 amount);
    event CollectRedemption(address indexed redeem_user,uint256 amount);
    event Buyback(address indexed buyback_user,uint256 amount);
    event RecollateralizeSTC(address indexed recollateralize_user,uint256 amount);

}
