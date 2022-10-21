pragma solidity ^0.6.6;


interface BPool {

    function getFinalTokens() external view returns (address[] memory tokens);
    function getNormalizedWeight(address token) external view returns (uint);
    function getBalance(address token) external view returns (uint);
    function totalSupply() external view returns (uint);
 
}
