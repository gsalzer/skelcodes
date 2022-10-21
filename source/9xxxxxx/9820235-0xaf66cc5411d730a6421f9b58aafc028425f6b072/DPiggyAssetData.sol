pragma solidity ^0.6.4;

import "DPiggyBaseProxyData.sol";
import "ReentrancyGuard.sol";

/**
 * @title DPiggyAssetData
 * @dev Contract for all dPiggy asset stored data.
 * It must inherit from DPiggyBaseProxyData contract for properly generate the proxy.
 * Each dPiggy asset has your own DPiggyAssetData.
 */
contract DPiggyAssetData is DPiggyBaseProxyData, ReentrancyGuard {
    
    /**
     * @dev The Struct to store each Compound redeem execution data.
     */
    struct Execution {
        /**
         * @dev The time in Unix.
         */
        uint256 time;
        
        /**
         * @dev The calculated rate based on Dai amount variation on Compound.
         */
        uint256 rate;
        
        /**
         * @dev The total amount of Dai on Compound.
         */
        uint256 totalDai;
        
        /**
         * @dev The amount of Dai redeemed on Compound.
         */
        uint256 totalRedeemed;
        
        /**
         * @dev The amount of asset purchased.
         */
        uint256 totalBought;
        
        /**
         * @dev The total of Dai deposited on the contract.
         */
        uint256 totalBalance;
        
        /**
         * @dev The total of Dai with fee exemption.
         */
        uint256 totalFeeDeduction;
        
        /**
         * @dev The total of Dai redeemed that was regarded as the fee.
         */
        uint256 feeAmount;
    }
    
    /**
     * @dev The Struct to store the user data.
     */
    struct UserData {
        /**
         * @dev The last execution Id on deposit.
         */
        uint256 baseExecutionId;
        
        /**
         * @dev The rate on deposit.
         * The value is the weighted average of all deposit rates with the same base execution Id.
         * It is used to calculate the user's corresponding profit on the next Compound redeem execution (baseExecutionId + 1).
         */
        uint256 baseExecutionAvgRate;
        
        /**
         * @dev The amount of Dai on deposit.
         * The value is the amount of Dai accumulated of all deposits with the same base execution Id.
         */
        uint256 baseExecutionAccumulatedAmount;
        
        /**
         * @dev The accumulated weight for the rate calculation.
         * The value is auxiliary for the base execution rate calculation for all deposits with the same base execution Id.
         */
        uint256 baseExecutionAccumulatedWeightForRate;
        
        /**
         * @dev The amount of Dai that will be applied the fee on the next Compound redeem execution (baseExecutionId + 1).
         */
        uint256 baseExecutionAmountForFee;
        
        /**
         * @dev The total of Dai deposited.
         */
        uint256 currentAllocated;
        
        /**
         * @dev The total of Dai previously deposited before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousAllocated;
        
        /**
         * @dev The previous Dai profit before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousProfit;
        
        /**
         * @dev The previous asset amount before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousAssetAmount;
        
        /**
         * @dev The previous fee on Dai before the regarded deposit.
         * The deposits are regarded the same if they have the same base execution Id.
         */
        uint256 previousFeeAmount;
        
        /**
         * @dev The total amount of asset redeemed.
         */
        uint256 redeemed;
    }
    
    /**
     * @dev Emitted when the minimum time between Compound redeem executions has been changed.
     * @param newTime The new minimum time between Compound redeem executions.
     * @param oldTime The previous minimum time between Compound redeem executions.
     */
    event SetMinimumTimeBetweenExecutions(uint256 newTime, uint256 oldTime);
    
    /**
     * @dev Emitted when a user has deposited Dai on the contract.
     * @param user The user's address.
     * @param amount The amount of Dai deposited.
     * @param rate The calculated rate.
     * @param baseExecutionId The last Compound redeem execution Id.
     * @param baseExecutionAmountForFee The amount of Dai that will be applied the fee on the next Compound redeem execution (baseExecutionId + 1).
     */
    event Deposit(address indexed user, uint256 amount, uint256 rate, uint256 baseExecutionId, uint256 baseExecutionAmountForFee);
    
    /**
     * @dev Emitted when a user has redeemed the asset profit on the contract.
     * @param user The user's address.
     * @param amount The amount of asset redeemed.
     */
    event Redeem(address indexed user, uint256 amount);
    
    /**
     * @dev Emitted when a Compound redeem has been executed.
     * @param executionId The respective Id.
     * @param rate The calculated rate.
     * @param totalBalance The total of Dai deposited on the contract.
     * @param totalRedeemed The amount of Dai redeemed on Compound.
     * @param fee The total of Dai redeemed that was regarded as the fee.
     * @param totalBought The amount of asset purchased.
     * @param totalAucBurned The amount of Auc purchased and burned with the fee.
     */
    event CompoundRedeem(uint256 indexed executionId, uint256 rate, uint256 totalBalance, uint256 totalRedeemed, uint256 fee, uint256 totalBought, uint256 totalAucBurned);
    
    /**
     * @dev Emitted when a user has finished the own participation on the dPiggy asset.
     * All asset profit is redeemed as well as all the Dai deposited. 
     * @param user The user's address.
     * @param totalRedeemed The amount of Dai redeemed on Compound.
     * @param yield The user yield in Dai redeemed since the last Compound redeem execution.
     * @param fee The total of Dai redeemed that was regarded as the fee.
     * @param totalAucBurned The amount of Auc purchased and burned with the fee.
     */
    event Finish(address indexed user, uint256 totalRedeemed, uint256 yield, uint256 fee, uint256 totalAucBurned);
    
    /**
     * @dev The ERC20 token address on the chain or '0x0' for Ethereum. 
     * It is the asset for the respective contract. 
     */
    address public tokenAddress;
    
    /**
     * @dev Minimum time in seconds between executions to run the Compound redeem.
     */
    uint256 public minimumTimeBetweenExecutions;
    
    /**
     * @dev Last Compound redeem execution Id (it is an incremental number).
     */
    uint256 public executionId;
    
    /**
     * @dev The total balance of Dai deposited.
     */
    uint256 public totalBalance;
    
    /**
     * @dev The amount of deposited Dai that has a fee exemption due to the Auc escrowed.
     */
    uint256 public feeExemptionAmountForAucEscrowed;
    
    /**
     * @dev It indicates if the contract asset is the cDai.
     */
    bool public isCompound;
    
    /**
     * @dev The difference between the amount of Dai deposited and the respective value normalized to the last Compound redeem execution time.
     * _key is the execution Id.
     * _value is the difference of Dai.
     */
    mapping(uint256 => uint256) public totalBalanceNormalizedDifference;
    
    /**
     * @dev The amount of Dai that has a fee exemption for the respective execution due to the user deposit time.
     * _key is the execution Id.
     * _value is the amount of Dai.
     * The user amount of Dai proportion is calculated based on the difference between the deposit time and the next execution time.
     */
    mapping(uint256 => uint256) public feeExemptionAmountForUserBaseData;
    
    /**
     * @dev The Compound redeem executions data.
     * _key is the execution Id.
     * _value is the execution data.
     */
    mapping(uint256 => Execution) public executions;
    
    /**
     * @dev The user data for the asset.
     * _key is the user address.
     * _value is the user data.
     */
    mapping(address => UserData) public usersData;
}

