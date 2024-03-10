pragma solidity ^0.5.16;

/**
 * @title Aegis InterestRateModel interface
 * @author Aegis
 */
contract InterestRateModel {
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param _cash The total amount of cash the market has
      * @param _borrows The total amount of borrows the market has outstanding
      * @param _reserves The total amnount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint _cash, uint _borrows, uint _reserves) external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param _cash The total amount of cash the market has
      * @param _borrows The total amount of borrows the market has outstanding
      * @param _reserves The total amnount of reserves the market has
      * @param _reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint _cash, uint _borrows, uint _reserves, uint _reserveFactorMantissa) external view returns (uint);
}
