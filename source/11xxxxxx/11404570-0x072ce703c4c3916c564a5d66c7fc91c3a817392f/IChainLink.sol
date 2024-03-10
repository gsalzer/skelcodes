pragma solidity >=0.6.0;

interface IChainLinkInterface {

    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);

}
