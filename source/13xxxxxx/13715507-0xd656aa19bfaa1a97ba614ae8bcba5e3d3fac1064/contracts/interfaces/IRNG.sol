pragma solidity ^0.8.0;

interface IRNG {
    function requestRandomNumber( ) external returns (bytes32);
    function requestRandomNumberWithCallback( ) external returns (bytes32);
    function isRequestComplete(bytes32 requestId) external view returns (bool isCompleted);
    function randomNumber(bytes32 requestId) external view returns (uint256 randomNum);
}


