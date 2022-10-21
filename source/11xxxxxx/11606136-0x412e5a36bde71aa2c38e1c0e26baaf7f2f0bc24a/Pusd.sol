// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IERC20.sol";
import "./ERC20Custom.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./PEGS.sol";
import "./PusdPool.sol";
import "./UniswapPairOracle.sol";
import "./ChainlinkETHUSDPriceConsumer.sol";
import "./AccessControl.sol";

contract PUSDStablecoin is ERC20Custom, AccessControl {
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */
    enum PriceChoice { PUSD, PEGS }
    ChainlinkETHUSDPriceConsumer private eth_usd_pricer;
    uint8 private eth_usd_pricer_decimals;
    UniswapPairOracle private pusdEthOracle;
    UniswapPairOracle private pegsEthOracle;
    string public symbol;
    string public name;
    uint8 public constant decimals = 18;
    address public owner_address;
    address public creator_address;
    address public timelock_address; // Governance timelock address
    address public controller_address; // Controller contract to dynamically adjust system parameters automatically
    address public pegs_address;
    address public pusd_eth_oracle_address;
    address public pegs_eth_oracle_address;
    address public weth_address;
    address public eth_usd_consumer_address;
    uint256 public constant genesis_supply = 3600e18; // 2M PUSD (only for testing, genesis supply will be 3.6k on Mainnet). This is to help with establishing the Uniswap pools, as they need liquidity

    // The addresses in this array are added by the oracle and these contracts are able to mint pusd
    address[] public pusd_pools_array;

    // Mapping is also used for faster verification
    mapping(address => bool) public pusd_pools; 

    // Constants for various precisions
    uint256 private constant PRICE_PRECISION = 1e6;
    
    uint256 public global_collateral_ratio; // 6 decimals of precision, e.g. 924102 = 0.924102
    uint256 public redemption_fee = 3000; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public minting_fee = 3000; // 6 decimals of precision, divide by 1000000 in calculations for fee
    uint256 public pusd_step; // Amount to change the collateralization ratio by upon refreshCollateralRatio()
    uint256 public refresh_cooldown; // Seconds to wait before being able to run refreshCollateralRatio() again
    uint256 public price_target; // The price of PUSD at which the collateral ratio will respond to; this value is only used for the collateral ratio mechanism and not for minting and redeeming which are hardcoded at $1
    uint256 public price_band; // The bound above and below the price target at which the refreshCollateralRatio() will not change the collateral ratio

    address public DEFAULT_ADMIN_ADDRESS;
    bytes32 public constant COLLATERAL_RATIO_PAUSER = keccak256("COLLATERAL_RATIO_PAUSER");
    bool public collateral_ratio_paused = true;

    /* ========== MODIFIERS ========== */

    modifier onlyCollateralRatioPauser() {
        require(hasRole(COLLATERAL_RATIO_PAUSER, msg.sender));
        _;
    }

    modifier onlyPools() {
       require(pusd_pools[msg.sender] == true, "Only pusd pools can call this function");
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
            || pusd_pools[msg.sender] == true, 
            "You are not the owner, the governance timelock, or a pool");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(
        string memory _name,
        string memory _symbol,
        address _creator_address,
        address _timelock_address
    ) public {
        name = _name;
        symbol = _symbol;
        creator_address = _creator_address;
        timelock_address = _timelock_address;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DEFAULT_ADMIN_ADDRESS = _msgSender();
        owner_address = _creator_address;
        _mint(creator_address, genesis_supply);
        grantRole(COLLATERAL_RATIO_PAUSER, creator_address);
        grantRole(COLLATERAL_RATIO_PAUSER, timelock_address);
        pusd_step = 2500; // 6 decimals of precision, equal to 0.25%
        global_collateral_ratio = 1000000; // Pusd system starts off fully collateralized (6 decimals of precision)
        refresh_cooldown = 3600; // Refresh cooldown period is set to 1 hour (3600 seconds) at genesis
        price_target = 1000000; // Collateral ratio will adjust according to the $1 price target at genesis
        price_band = 5000; // Collateral ratio will not adjust if between $0.995 and $1.005 at genesis
    }

    /* ========== VIEWS ========== */

    // Choice = 'PUSD' or 'PEGS' for now
    function oracle_price(PriceChoice choice) internal view returns (uint256) {
        // Get the ETH / USD price first, and cut it down to 1e6 precision
        uint256 eth_usd_price = uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
        uint256 price_vs_eth;

        if (choice == PriceChoice.PUSD) {
            price_vs_eth = uint256(pusdEthOracle.consult(weth_address, PRICE_PRECISION)); // How much PUSD if you put in PRICE_PRECISION WETH
        }
        else if (choice == PriceChoice.PEGS) {
            price_vs_eth = uint256(pegsEthOracle.consult(weth_address, PRICE_PRECISION)); // How much PEGS if you put in PRICE_PRECISION WETH
        }
        else revert("INVALID PRICE CHOICE. Needs to be either 0 (PUSD) or 1 (PEGS)");

        // Will be in 1e6 format
        return eth_usd_price.mul(PRICE_PRECISION).div(price_vs_eth);
    }

    // Returns X PUSD = 1 USD
    function pusd_price() public view returns (uint256) {
        return oracle_price(PriceChoice.PUSD);
    }

    // Returns X PEGS = 1 USD
    function pegs_price()  public view returns (uint256) {
        return oracle_price(PriceChoice.PEGS);
    }

    function eth_usd_price() public view returns (uint256) {
        return uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals);
    }

    // This is needed to avoid costly repeat calls to different getter functions
    // It is cheaper gas-wise to just dump everything and only use some of the info
    function pusd_info() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (
            oracle_price(PriceChoice.PUSD), // pusd_price()
            oracle_price(PriceChoice.PEGS), // pegs_price()
            totalSupply(), // totalSupply()
            global_collateral_ratio, // global_collateral_ratio()
            globalCollateralValue(), // globalCollateralValue
            minting_fee, // minting_fee()
            redemption_fee, // redemption_fee()
            uint256(eth_usd_pricer.getLatestPrice()).mul(PRICE_PRECISION).div(uint256(10) ** eth_usd_pricer_decimals) //eth_usd_price
        );
    }

    // Iterate through all pusd pools and calculate all value of collateral in all pools globally 
    function globalCollateralValue() public view returns (uint256) {
        uint256 total_collateral_value_d18 = 0; 

        for (uint i = 0; i < pusd_pools_array.length; i++){ 
            // Exclude null addresses
            if (pusd_pools_array[i] != address(0)){
                total_collateral_value_d18 = total_collateral_value_d18.add(PusdPool(pusd_pools_array[i]).collatDollarBalance());
            }

        }
        return total_collateral_value_d18;
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    
    // There needs to be a time interval that this can be called. Otherwise it can be called multiple times per expansion.
    uint256 public last_call_time; // Last time the refreshCollateralRatio function was called
    function refreshCollateralRatio() public {
        require(collateral_ratio_paused == false, "Collateral Ratio has been paused");
        uint256 pusd_price_cur = pusd_price();
        require(block.timestamp - last_call_time >= refresh_cooldown, "Must wait for the refresh cooldown since last refresh");

        // Step increments are 0.25% (upon genesis, changable by setPusdStep()) 
        
        if (pusd_price_cur > price_target.add(price_band)) { //decrease collateral ratio
            if(global_collateral_ratio <= pusd_step){ //if within a step of 0, go to 0
                global_collateral_ratio = 0;
            } else {
                global_collateral_ratio = global_collateral_ratio.sub(pusd_step);
            }
        } else if (pusd_price_cur < price_target.sub(price_band)) { //increase collateral ratio
            if(global_collateral_ratio.add(pusd_step) >= 1000000){
                global_collateral_ratio = 1000000; // cap collateral ratio at 1.000000
            } else {
                global_collateral_ratio = global_collateral_ratio.add(pusd_step);
            }
        }

        last_call_time = block.timestamp; // Set the time of the last expansion
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Used by pools when user redeems
    function pool_burn_from(address b_address, uint256 b_amount) public onlyPools {
        super._burnFrom(b_address, b_amount);
        emit PUSDBurned(b_address, msg.sender, b_amount);
    }

    // This function is what other pusd pools will call to mint new PUSD 
    function pool_mint(address m_address, uint256 m_amount) public onlyPools {
        super._mint(m_address, m_amount);
        emit PUSDMinted(msg.sender, m_address, m_amount);
    }

    // Adds collateral addresses supported, such as tether and busd, must be ERC20 
    function addPool(address pool_address) public onlyByOwnerOrGovernance {
        require(pusd_pools[pool_address] == false, "address already exists");
        pusd_pools[pool_address] = true; 
        pusd_pools_array.push(pool_address);
    }

    // Remove a pool 
    function removePool(address pool_address) public onlyByOwnerOrGovernance {
        require(pusd_pools[pool_address] == true, "address doesn't exist already");
        
        delete pusd_pools[pool_address];

        for (uint i = 0; i < pusd_pools_array.length; i++){ 
            if (pusd_pools_array[i] == pool_address) {
                pusd_pools_array[i] = address(0); // This will leave a null in the array and keep the indices the same
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

    function setPusdStep(uint256 _new_step) public onlyByOwnerOrGovernance {
        pusd_step = _new_step;
    }  

    function setPriceTarget (uint256 _new_price_target) public onlyByOwnerOrGovernance {
        price_target = _new_price_target;
    }

    function setRefreshCooldown(uint256 _new_cooldown) public onlyByOwnerOrGovernance {
    	refresh_cooldown = _new_cooldown;
    }

    function setPEGSAddress(address _pegs_address) public onlyByOwnerOrGovernance {
        pegs_address = _pegs_address;
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

    // Sets the PUSD_ETH Uniswap oracle address 
    function setPUSDEthOracle(address _pusd_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        pusd_eth_oracle_address = _pusd_oracle_addr;
        pusdEthOracle = UniswapPairOracle(_pusd_oracle_addr); 
        weth_address = _weth_address;
    }

    // Sets the PEGS_ETH Uniswap oracle address 
    function setPEGSEthOracle(address _pegs_oracle_addr, address _weth_address) public onlyByOwnerOrGovernance {
        pegs_eth_oracle_address = _pegs_oracle_addr;
        pegsEthOracle = UniswapPairOracle(_pegs_oracle_addr);
        weth_address = _weth_address;
    }

    function toggleCollateralRatio() public onlyCollateralRatioPauser {
        collateral_ratio_paused = !collateral_ratio_paused;
    }

    /* ========== EVENTS ========== */

    // Track PUSD burned
    event PUSDBurned(address indexed from, address indexed to, uint256 amount);

    // Track PUSD minted
    event PUSDMinted(address indexed from, address indexed to, uint256 amount);
}

