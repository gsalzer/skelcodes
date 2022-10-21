// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "../Common/Context.sol";
import "../ERC20/IERC20.sol";
import "../ERC20/ERC20Custom.sol";
import "../ERC20/ERC20.sol";
import "../Math/SafeMath.sol";
import "./Pools/IXUSDPool.sol";
import "../Oracle/UniswapPairOracle.sol";
import "../Oracle/ChainlinkETHUSDPriceConsumer.sol";

contract XUSDStablecoin is ERC20Custom {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { XUSD, XUS }
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    UniswapPairOracle private xusdEthOracle;
    UniswapPairOracle private xusEthOracle;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public owner_address;
    address public timelock_address; // Governance timelock address
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    address public xus_address;
    address public xusd_eth_oracle_address;
    address public xus_eth_oracle_address;
    address public weth_address;
    address public eth_usd_consumer_address;

    // mint 500 at genesis to bootstrap liquidity
    uint256 public constant genesis_supply = 500e18;

    // The addresses in this array are added by the oracle and these contracts are able to mint xusd
    address[] public xusd_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public xusd_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee = 3000; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee = 7000; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public xusd_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of XUSD at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    bool public collateral_ratio_paused = false;

    /* ========== MODIFIERS ========== */

    modifier onlyPools() {
       require(xusd_pools[msg.sender] == true, "Only xusd pools can call this function");
        _;
    } 
    
    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address || msg.sender == controller_address, "You are not the owner, controller, or the governance timelock");
        _;
    }

    modifier onlyByOwnerGovernanceOrPool() {
        require(
            msg.sender == owner_address 
            || msg.sender == timelock_address 
            || xusd_pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        timelock_address = _timelock_address;
        owner_address = msg.sender;
        _mint(owner_address, genesis_supply);
        xusd_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // XUSD system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
    }

    // FOR TEST ONLY! REMOVE WHEN MAINNET!!!
    // function setCR(uint256 _cr) external onlyByOwnerOrGovernance {
    //     global_collateral_ratio = _cr;
    // }

    /* ========== VIEWS ========== */

    // Choice = 'XUSD' or 'XUS' for now
    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth;

        if (choice == PriceChoice.XUSD) {
            price_vs_eth = uint256(xusdEthOracle.consult(weth_address, PRICE_PRECISION)); // How much XUSD if you put in PRICE_PRECISION WETH
        }
        else if (choice == PriceChoice.XUS) {
            price_vs_eth = uint256(xusEthOracle.consult(weth_address, PRICE_PRECISION)); // How much XUS if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (XUSD) or 1 (XUS)");

        // Will be in 1e6 format
        return eth_usd_price.mul(PRICE_PRECISION).div(price_vs_eth);
    }

    // Returns X XUSD = 1 USD
    function xusd_price() public view returns (uint256) {
        return oracle_price(PriceChoice.XUSD);
    }

    // Returns X XUS = 1 USD
    function xus_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.XUS);
    }

    function eth_usd_price() public view returns (uint256) {
        return uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function xusd_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            oracle_price(PriceChoice.XUSD), // xusd_price()
            oracle_price(PriceChoice.XUS), // xus_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee, // redemption_fee()
            uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all xusd pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < xusd_pools_array.length; i++){ 
            // Exclude null addresses
            if (xusd_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(IXUSDPool(xusd_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 xusd_price_cur = xusd_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setXUSDStep()) 
        
        if (xusd_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= xusd_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(xusd_step);
            }
        } else if (xusd_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(xusd_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(xusd_step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit XUSDBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other xusd pools will call to mint new XUSD 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit XUSDMinted(msg.sender, m_address, m_amount);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(xusd_pools[pool_address] == false, "address already exists");
        xusd_pools[pool_address] = true; 
        xusd_pools_array.push(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
        require(xusd_pools[pool_address] == true, "address doesn't exist already");
        
        // Delete from the mapping
        delete xusd_pools[pool_address];

        // 'Delete' from the array by setting the address to 0x0
        for (uint i = 0; i < xusd_pools_array.length; i++){ 
            if (xusd_pools_array[i] == pool_address) {
                xusd_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
                break;
            }
        }
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }

    function setRedemptionFee(uint256 red_fee) public onlyByOwnerOrGovernance {
        redemption_fee = red_fee;
    }

    function setMintingFee(uint256 min_fee) public onlyByOwnerOrGovernance {
        minting_fee = min_fee;
    }  

    function setXUSDStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        xusd_step = _new_step;
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setXUSAddress(address _xus_address) public onlyByOwnerOrGovernance {
        xus_address = _xus_address;
    }

    function setETHUSDOracle(address _eth_usd_consumer_address) public onlyByOwnerOrGovernance {
        eth_usd_consumer_address = _eth_usd_consumer_address;
        eth_usd_pricer = ChainlinkETHUSDPriceConsumer(eth_usd_consumer_address);
        eth_usd_pricer_decimals = eth_usd_pricer.getDecimals();
    }

    function setTimelock(address new_timelock) external onlyByOwnerOrGovernance {
        timelock_address = new_timelock;
    }

    function setController(address _controller_address) external onlyByOwnerOrGovernance {
        controller_address = _controller_address;
    }

    function setPriceBand(uint256 _price_band) external onlyByOwnerOrGovernance {
        price_band = _price_band;
    }

    // Sets the XUSD_ETH Uniswap oracle address 
    function setXUSDEthOracle(address _xusd_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        xusd_eth_oracle_address = _xusd_oracle_addr;
        xusdEthOracle = UniswapPairOracle(_xusd_oracle_addr); 
        weth_address = _weth_address;
    }

    // Sets the XUS_ETH Uniswap oracle address 
    function setXUSEthOracle(address _xus_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        xus_eth_oracle_address = _xus_oracle_addr;
        xusEthOracle = UniswapPairOracle(_xus_oracle_addr);
        weth_address = _weth_address;
    }

    function toggleCollateralRatio() public onlyByOwnerOrGovernance {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    /* ========== EVENTS ========== */

    // Track XUSD burned
    event XUSDBurned(address indexed from, address indexed to, uint256 amount);

    // Track XUSD minted
    event XUSDMinted(address indexed from, address indexed to, uint256 amount);
}

