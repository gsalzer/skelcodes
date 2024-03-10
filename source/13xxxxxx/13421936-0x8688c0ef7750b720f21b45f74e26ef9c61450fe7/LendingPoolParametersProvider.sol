pragma solidity ^0.5.0;


import "./VersionedInitializable.sol";
import "./UintStorage.sol";

/**
* LendingPoolParametersProvider contract
* -
* stores the configuration parameters of the Lending Pool contract
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

contract LendingPoolParametersProvider is VersionedInitializable {

    uint256 private constant MAX_STABLE_RATE_BORROW_SIZE_PERCENT = 25;
    uint256 private constant REBALANCE_DOWN_RATE_DELTA = (1e27)/5;
    uint256 private constant FLASHLOAN_FEE_TOTAL = 35;
    uint256 private constant FLASHLOAN_FEE_PROTOCOL = 3000;

    uint256 constant private DATA_PROVIDER_REVISION = 0x1;

    function getRevision() internal pure returns(uint256) {
        return DATA_PROVIDER_REVISION;
    }

    /**
    * @dev initializes the LendingPoolParametersProvider after it's added to the proxy
    * @param _addressesProvider the address of the LendingPoolAddressesProvider
    */
    function initialize(address _addressesProvider) public initializer {
    }
    /**
    * @dev returns the maximum stable rate borrow size, in percentage of the available liquidity.
    **/
    function getMaxStableRateBorrowSizePercent() external pure returns (uint256)  {
        return MAX_STABLE_RATE_BORROW_SIZE_PERCENT;
    }

    /**
    * @dev returns the delta between the current stable rate and the user stable rate at
    *      which the borrow position of the user will be rebalanced (scaled down)
    **/
    function getRebalanceDownRateDelta() external pure returns (uint256) {
        return REBALANCE_DOWN_RATE_DELTA;
    }

    /**
    * @dev returns the fee applied to a flashloan and the portion to redirect to the protocol, in basis points.
    **/
    function getFlashLoanFeesInBips() external pure returns (uint256, uint256) {
        return (FLASHLOAN_FEE_TOTAL, FLASHLOAN_FEE_PROTOCOL);
    }
}

