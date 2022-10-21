pragma solidity ^0.6.4;

import "DPiggyBaseProxyData.sol";
import "ReentrancyGuard.sol";
import "DPiggyInterface.sol";

/**
 * @title DPiggyData
 * @dev Contract for all dPiggy stored data.
 * It must inherit from DPiggyBaseProxyData contract for properly generate the proxy.
 */
contract DPiggyData is DPiggyBaseProxyData, ReentrancyGuard, DPiggyDataInterface {
    
    /**
     * @dev The Struct to store each user escrow data.
     */
    struct EscrowData {
        /**
         * @dev The amount of Auc escrowed.
         */
        uint256 amount;
        
        /**
         * @dev The time in Unix that the escrow occurred.
         */
        uint256 time;
    }
    
    /**
     * @dev The Struct to store each dPiggy asset data.
     */
    struct AssetData {
        /**
         * @dev The proxy contract address that runs the asset base implementation contract.
         */
        address proxy;
        
        /**
         * @dev It defines whether the deposit of Dai is allowed.
         */
        bool depositAllowed;
        
        /**
         * @dev The creation time in Unix.
         */
        uint256 time;
        
        /**
         * @dev The minimum amount of Dai that can be deposited.
         */
        uint256 minimumDeposit;
    }
    
    /**
     * @dev Emitted when the daily fee has been changed.
     * @param newDailylFee The new daily fee.
     * @param oldDailylFee The previous daily fee.
     */
    event SetDailyFee(uint256 newDailylFee, uint256 oldDailylFee);
    
    /**
     * @dev Emitted when the minimum amount of Auc escrowed to have the fee exemption has been changed.
     * @param newMinimumAuc The new minimum amount of Auc escrowed to have the fee exemption.
     * @param oldMinimumAuc The previous minimum amount of Auc escrowed to have the fee exemption.
     */
    event SetMinimumAucToFreeFee(uint256 newMinimumAuc, uint256 oldMinimumAuc);
    
    /**
     * @dev Emitted when a user has escrowed Auc on the contract.
     * @param user The user's address.
     * @param amount The amount of Auc escrowed.
     */
    event SetUserAucEscrow(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a user has redeemed the Auc escrowed.
     * @param user The user's address.
     * @param amount The amount of Auc redeemed.
     */
    event RedeemUserAucEscrow(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a new dPiggy asset has been created.
     * @param tokenAddress The ERC20 token address (0x0 for Ethereum).
     * @param proxy The proxy contract address created that runs the asset base implementation contract.
     */
    event SetNewAsset(address indexed tokenAddress, address proxy);
    
    /**
     * @dev Emitted when the dPiggy asset deposit permission has changed.
     * @param tokenAddress The ERC20 token address (0x0 for Ethereum).
     * @param newDepositAllowed The new condition for the permission for the deposit of Dai.
     * @param oldDepositAllowed The previous condition for the permission for the deposit of Dai.
     */
    event SetAssetDepositAllowed(address indexed tokenAddress, bool newDepositAllowed, bool oldDepositAllowed);
    
    /**
     * @dev Emitted when the dPiggy asset minimum Dai for deposit has changed.
     * @param tokenAddress The ERC20 token address (0x0 for Ethereum).
     * @param newMinimumDeposit The new minimum amount of Dai that can be deposited.
     * @param oldMinimumDeposit The previous minimum amount of Dai that can be deposited.
     */
    event SetAssetMinimumDeposit(address indexed tokenAddress, uint256 newMinimumDeposit, uint256 oldMinimumDeposit);

    /**
     * @dev Address for the Auc token contract.
     */
    address public override(DPiggyDataInterface) auc;
    
    /**
     * @dev Address for the Dai token contract.
     */
    address public override(DPiggyDataInterface) dai;
    
    /**
     * @dev Address for the cDai (the Compound contract).
     */
    address public override(DPiggyDataInterface) compound;
    
    /**
     * @dev Address for the Uniswap Dai exchange contract.
     */
    address public override(DPiggyDataInterface) exchange;
    
    /**
     * @dev Address for the Uniswap factory contract.
     */
    address public uniswapFactory;
    
    /**
     * @dev Address for the asset base implementation contract.
     */
    address public assetImplementation;
    
    /**
     * @dev The percentage precision. 
     * The value represents the 100%.
     */
    uint256 public override(DPiggyDataInterface) percentagePrecision;
    
    /**
     * @dev The minimum amount of Auc escrowed to have the fee exemption.
     */
    uint256 public minimumAucToFreeFee;
    
    /**
     * @dev Total amount of Auc escrowed.
     */
    uint256 public totalEscrow;
    
    /**
     * @dev The maximum value that can be defined for the daily fee percentage.
     */
    uint256 public maximumDailyFee;
    
    /**
     * @dev The daily fee percentage (with percentage precision).
     */
    uint256 public dailyFee;
    
    /**
     * @dev The number of dPiggy assets.
     */
    uint256 public numberOfAssets;
    
    /**
     * @dev Array for all dPiggy assets. 
     * The ERC20 token addresses (0x0 for Ethereum).
     */
    address[] public assets;
    
    /**
     * @dev The user escrow data.
     * _key is the user address.
     * _value is the user escrow data.
     */
    mapping(address => EscrowData) public usersEscrow;
    
    /**
     * @dev The dPiggy asset data.
     * _key is the ERC20 token address (0x0 for Ethereum).
     * _value is the dPiggy asset data.
     */
    mapping(address => AssetData) public assetsData;
}
