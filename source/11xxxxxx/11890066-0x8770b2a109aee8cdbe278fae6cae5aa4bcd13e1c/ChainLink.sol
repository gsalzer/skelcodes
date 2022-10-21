pragma solidity 0.4.24;

import "./AggregatorV3Interface.sol";
import './TestTokens.sol';

contract ChainLink {
    
    mapping(address => AggregatorV3Interface) internal priceContractMapping;
    mapping (address => bool) public assetsWithPriceFeedBasedOnUSD;
    address public admin;
    bool public paused = false;
    address public wethAddress;
    AggregatorV3Interface public USDETHPriceFeed;

    /**
     * Sets the initial assets and admin
     * Add assets and set Weth Address using their own functions
     */
    constructor() public {
        admin = msg.sender;
    }
    
    /**
     * Modifier to restrict functions only by admins
     */
    modifier onlyAdmin() {
        require(msg.sender == admin,"Only the Admin can perform this operation");
        _;
    }
    
    /**
     * Event declarations for all the operations of this contract
     */
    event assetAdded(address assetAddress, address priceFeedContract);
    event assetRemoved(address assetAddress);
    event adminChanged(address oldAdmin, address newAdmin);
    event wethAddressSet(address wethAddress);
    event USDETHPriceFeedSet(address USDETHPriceFeed);
    event contractPausedOrUnpaused(bool currentStatus);

    /**
     * Allows admin to add a new asset for price tracking
     */
    function addAsset(address assetAddress, address priceFeedContract, bool _assetWithPriceFeedBasedOnUSD) public onlyAdmin {
        if (_assetWithPriceFeedBasedOnUSD) {
            require(USDETHPriceFeed != address(0),"USDETHPriceFeed not set");
        }
        priceContractMapping[assetAddress] = AggregatorV3Interface(priceFeedContract);
        assetsWithPriceFeedBasedOnUSD[assetAddress] = _assetWithPriceFeedBasedOnUSD;
        emit assetAdded(assetAddress, priceFeedContract);
    }
    
    /**
     * Allows admin to remove an existing asset from price tracking
     */
    function removeAsset(address assetAddress) public onlyAdmin {
        priceContractMapping[assetAddress] = AggregatorV3Interface(address(0));
        emit assetRemoved(assetAddress);
    }
    
    /**
     * Allows admin to change the admin of the contract
     */
    function changeAdmin(address newAdmin) public onlyAdmin {
        emit adminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    /**
     * Allows admin to set the weth address
     */
    function setWethAddress(address _wethAddress) public onlyAdmin {
        wethAddress = _wethAddress;
        emit wethAddressSet(_wethAddress);
    }

    /**
     * Allows admin to set the weth address
     */
    function setUSDETHPriceFeedAddress(AggregatorV3Interface _USDETHPriceFeed) public onlyAdmin {
        USDETHPriceFeed = _USDETHPriceFeed;
        emit USDETHPriceFeedSet(_USDETHPriceFeed);
    }

    /**
     * Allows admin to pause and unpause the contract
     */
    function togglePause() public onlyAdmin {
        if (paused) {
            paused = false;
            emit contractPausedOrUnpaused(false);
        }
        else {
            paused = true;
            emit contractPausedOrUnpaused(true);
        }
    }

    /**
     * Returns the latest price
     */
    function getAssetPrice(address asset) public view returns (uint) {
        // Return 1 * 10^18 for WETH, otherwise return actual price
        if(!paused && asset == wethAddress) {
            return 1000000000000000000;
        }
        // Capture the decimals in the ERC20 token
        uint8 assetDecimals = TestTokens(asset).decimals();
        if(!paused && priceContractMapping[asset] != address(0)) {
            (
                uint80 roundID, 
                int price,
                uint startedAt,
                uint timeStamp,
                uint80 answeredInRound
            ) = priceContractMapping[asset].latestRoundData();
            // If the round is not complete yet, timestamp is 0
            require(timeStamp > 0, "Round not complete");
            // Calculate USD/ETH price for contracts using USD based price feed
            if(assetsWithPriceFeedBasedOnUSD[asset]) {
                int priceUSD;
                (
                    roundID, 
                    priceUSD,
                    startedAt,
                    timeStamp,
                    answeredInRound
                ) = USDETHPriceFeed.latestRoundData();
                // If the round is not complete yet, timestamp is 0
                require(timeStamp > 0, "Round not complete");
                uint returnedPrice = uint(price) * uint(priceUSD) / (10 ** 8);
                return returnedPrice;
            } else {
                if(price >0) {
                // Magnify the result based on decimals
                return (uint(price) * (10 ** (18 - uint(assetDecimals))));
            }
            else {
                return 0;
            }
            }
        }
        else {
            return 0;
        }
    }

    function fallback() public payable {
        require(msg.sender.send(msg.value),"Fallback function initiated but refund failed");
    }
}
