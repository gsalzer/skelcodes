pragma solidity ^0.5.6;


contract IAllowanceChecker {

    /**
    * @dev Function to get stable coin allowed amount for originater
    * @param _coinAddress address of stable coin
    * @param _coinHolderAddress address of coin holder
    * @return uint256 that indicates amount of allowed amount for originate address
    */
    function getCoinAllowance(
        address _coinAddress,
        address _coinHolderAddress
    )
    internal
    view
    returns (uint256);

}

