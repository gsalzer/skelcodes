//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);
    function calculateFeeBPS(uint256 _route) external view returns (uint256);
    function tokenToCToken(address) external view returns (address);
}

interface IAaveProtocolDataProvider {
    function getReserveConfigurationData(address asset) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, bool);
    function getReserveTokensAddresses(address asset) external view returns (address, address, address);
}
