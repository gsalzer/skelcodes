// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IOneInch {
    function FLAG_DISABLE_AAVE() external view returns (uint256);

    function FLAG_DISABLE_BANCOR() external view returns (uint256);

    function FLAG_DISABLE_BDAI() external view returns (uint256);

    function FLAG_DISABLE_CHAI() external view returns (uint256);

    function FLAG_DISABLE_COMPOUND() external view returns (uint256);

    function FLAG_DISABLE_CURVE_BINANCE() external view returns (uint256);

    function FLAG_DISABLE_CURVE_COMPOUND() external view returns (uint256);

    function FLAG_DISABLE_CURVE_SYNTHETIX() external view returns (uint256);

    function FLAG_DISABLE_CURVE_USDT() external view returns (uint256);

    function FLAG_DISABLE_CURVE_Y() external view returns (uint256);

    function FLAG_DISABLE_FULCRUM() external view returns (uint256);

    function FLAG_DISABLE_IEARN() external view returns (uint256);

    function FLAG_DISABLE_KYBER() external view returns (uint256);

    function FLAG_DISABLE_OASIS() external view returns (uint256);

    function FLAG_DISABLE_SMART_TOKEN() external view returns (uint256);

    function FLAG_DISABLE_UNISWAP() external view returns (uint256);

    function FLAG_DISABLE_WETH() external view returns (uint256);

    function FLAG_ENABLE_KYBER_BANCOR_RESERVE() external view returns (uint256);

    function FLAG_ENABLE_KYBER_OASIS_RESERVE() external view returns (uint256);

    function FLAG_ENABLE_KYBER_UNISWAP_RESERVE() external view returns (uint256);

    function FLAG_ENABLE_MULTI_PATH_DAI() external view returns (uint256);

    function FLAG_ENABLE_MULTI_PATH_ETH() external view returns (uint256);

    function FLAG_ENABLE_MULTI_PATH_USDC() external view returns (uint256);

    function FLAG_ENABLE_UNISWAP_COMPOUND() external view returns (uint256);

    function claimAsset(address asset, uint256 amount) external;

    function getExpectedReturn(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 parts,
        uint256 featureFlags
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);

    function isOwner() external view returns (bool);

    function oneSplitImpl() external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setNewImpl(address impl) external;

    function swap(
        address fromToken,
        address toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 featureFlags
    ) external payable;

    function transferOwnership(address newOwner) external;
}

