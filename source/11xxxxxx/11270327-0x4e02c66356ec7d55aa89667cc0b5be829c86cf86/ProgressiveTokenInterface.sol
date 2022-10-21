pragma solidity ^0.5.11;
interface ProgressiveTokenInterface {
    function oneDollarRate() external view returns(uint);
    function oneTokenCount() external view returns(uint);
    function addConvertedTokens(address _address) external;
}
