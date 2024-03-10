pragma solidity ^0.5.16;

import "./SToken.sol";
import "./PriceOracle.sol";

contract UnitrollerAdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of Unitroller
    */
    address public comptrollerImplementation;

    /**
    * @notice Pending brains of Unitroller
    */
    address public pendingComptrollerImplementation;
}

contract ComptrollerV1Storage is UnitrollerAdminStorage {

    /**
     * @notice Oracle which gives the price of any given asset
     */
    PriceOracle public oracle;

    /**
     * @notice Multiplier used to calculate the maximum repayAmount when liquidating a borrow
     */
    uint public closeFactorMantissa;

    /**
     * @notice Multiplier representing the discount on collateral that a liquidator receives
     */
    uint public liquidationIncentiveMantissa;

    /**
     * @notice Max number of assets a single account can participate in (borrow or use as collateral)
     */
    uint public maxAssets;

    /**
     * @notice Per-account mapping of "assets you are in", capped by maxAssets
     */
    mapping(address => SToken[]) public accountAssets;

}

contract ComptrollerV2Storage is ComptrollerV1Storage {
    struct Market {
        /// @notice Whether or not this market is listed
        bool isListed;

        /**
         * @notice Multiplier representing the most one can borrow against their collateral in this market.
         *  For instance, 0.9 to allow borrowing 90% of collateral value.
         *  Must be between 0 and 1, and stored as a mantissa.
         */
        uint collateralFactorMantissa;

        /// @notice Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;

        /// @notice Whether or not this market receives STRK
        bool isStriked;
    }

    /**
     * @notice Official mapping of sTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    mapping(address => Market) public markets;


    /**
     * @notice The Pause Guardian can pause certain actions as a safety mechanism.
     *  Actions which allow users to remove their own assets cannot be paused.
     *  Liquidation / seizing / transfer can only be paused globally, not by market.
     */
    address public pauseGuardian;
    bool public _mintGuardianPaused;
    bool public _borrowGuardianPaused;
    bool public transferGuardianPaused;
    bool public seizeGuardianPaused;
    mapping(address => bool) public mintGuardianPaused;
    mapping(address => bool) public borrowGuardianPaused;
}

contract ComptrollerV3Storage is ComptrollerV2Storage {
    struct StrikeMarketState {
        /// @notice The market's last updated strikeBorrowIndex or strikeSupplyIndex
        uint224 index;

        /// @notice The block number the index was last updated at
        uint32 block;
    }

    /// @notice A list of all markets
    SToken[] public allMarkets;

    /// @notice The rate at which the flywheel distributes STRK, per block
    uint public strikeRate;

    /// @notice The portion of strikeRate that each market currently receives
    mapping(address => uint) public strikeSpeeds;

    /// @notice The STRK market supply state for each market
    mapping(address => StrikeMarketState) public strikeSupplyState;

    /// @notice The STRK market borrow state for each market
    mapping(address => StrikeMarketState) public strikeBorrowState;

    /// @notice The STRK borrow index for each market for each supplier as of the last time they accrued STRK
    mapping(address => mapping(address => uint)) public strikeSupplierIndex;

    /// @notice The STRK borrow index for each market for each borrower as of the last time they accrued STRK
    mapping(address => mapping(address => uint)) public strikeBorrowerIndex;

    /// @notice The STRK accrued but not yet transferred to each user
    mapping(address => uint) public strikeAccrued;
}

