pragma solidity ^0.5.0;

/**
* ILendingRateOracle interface
* -
* Interface for the Populous borrow rate oracle. Provides the average market borrow rate to be used as a base for the stable borrow rate calculations
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface ILendingRateOracle {
    /**
    @dev returns the market borrow rate in ray
    **/
    function getMarketBorrowRate(address _asset) external view returns (uint256);

    /**
    @dev sets the market borrow rate. Rate value must be in ray
    **/
    function setMarketBorrowRate(address _asset, uint256 _rate) external;
}

