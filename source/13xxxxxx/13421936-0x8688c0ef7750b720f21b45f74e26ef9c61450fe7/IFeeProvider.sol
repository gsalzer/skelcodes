pragma solidity ^0.5.0;

/**
* IFeeProvider interface
* -
* Interface for the Populous fee provider.
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface IFeeProvider {
    function calculateLoanOriginationFee(address _user, uint256 _amount) external view returns (uint256);
    function getLoanOriginationFeePercentage() external view returns (uint256);
}

