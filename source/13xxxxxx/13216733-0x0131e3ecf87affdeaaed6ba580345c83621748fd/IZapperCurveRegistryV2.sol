// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IZapperCurveRegistryV2 {
    function CurveRegistry() external view returns (address);

    function FactoryRegistry() external view returns (address);

    function getDepositAddress(address swapAddress) external view returns (address depositAddress);

    function getNumTokens(address swapAddress) external view returns (uint256);

    function getPoolTokens(address swapAddress) external view returns (address[4] memory poolTokens);

    function getSwapAddress(address tokenAddress) external view returns (address swapAddress);

    function getTokenAddress(address swapAddress) external view returns (address tokenAddress);

    function isBtcPool(address swapAddress) external view returns (bool);

    function isCurvePool(address swapAddress) external view returns (bool);

    function isEthPool(address swapAddress) external view returns (bool);

    function isFactoryPool(address swapAddress) external view returns (bool);

    function isMetaPool(address swapAddress) external view returns (bool);

    function isOwner() external view returns (bool);

    function isUnderlyingToken(address swapAddress, address tokenContractAddress) external view returns (bool, uint256);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function shouldAddUnderlying(address) external view returns (bool);

    function transferOwnership(address newOwner) external;

    function updateDepositAddresses(address[] calldata swapAddresses, address[] calldata _depositAddresses) external;

    function updateShouldAddUnderlying(address[] calldata swapAddresses, bool[] calldata addUnderlying) external;

    function update_curve_registry() external;

    function update_factory_registry() external;

    function withdrawTokens(address[] calldata tokens) external;
}

