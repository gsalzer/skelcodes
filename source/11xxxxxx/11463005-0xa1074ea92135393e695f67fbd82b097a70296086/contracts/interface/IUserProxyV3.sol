pragma solidity ^0.6.0;

interface IUserProxyV3 {
    function spendFromUser(address user, address takerAssetAddr, uint256 takerAssetAmount) external;
}
