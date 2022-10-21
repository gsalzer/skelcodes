pragma solidity ^0.5.0;

/**
* IFlashLoanReceiver interface
* -
* implement this interface to develop a flashloan-compatible flashLoanReceiver contract
* -
* This contract was cloned from Populous and modified to work with the Populous World eco-system.
**/

interface IFlashLoanReceiver {

    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) external;
}

