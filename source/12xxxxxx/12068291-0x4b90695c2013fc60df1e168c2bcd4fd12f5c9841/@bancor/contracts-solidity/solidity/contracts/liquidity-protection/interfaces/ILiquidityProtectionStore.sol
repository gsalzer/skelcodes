// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../converter/interfaces/IConverterAnchor.sol";
import "../../token/interfaces/IDSToken.sol";
import "../../utility/interfaces/IOwned.sol";

/*
    Liquidity Protection Store interface
*/
interface ILiquidityProtectionStore is IOwned {
    function withdrawTokens(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    function protectedLiquidity(uint256 _id)
        external
        view
        returns (
            address,
            IDSToken,
            IERC20,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function addProtectedLiquidity(
        address _provider,
        IDSToken _poolToken,
        IERC20 _reserveToken,
        uint256 _poolAmount,
        uint256 _reserveAmount,
        uint256 _reserveRateN,
        uint256 _reserveRateD,
        uint256 _timestamp
    ) external returns (uint256);

    function updateProtectedLiquidityAmounts(
        uint256 _id,
        uint256 _poolNewAmount,
        uint256 _reserveNewAmount
    ) external;

    function removeProtectedLiquidity(uint256 _id) external;

    function lockedBalance(address _provider, uint256 _index) external view returns (uint256, uint256);

    function lockedBalanceRange(
        address _provider,
        uint256 _startIndex,
        uint256 _endIndex
    ) external view returns (uint256[] memory, uint256[] memory);

    function addLockedBalance(
        address _provider,
        uint256 _reserveAmount,
        uint256 _expirationTime
    ) external returns (uint256);

    function removeLockedBalance(address _provider, uint256 _index) external;

    function systemBalance(IERC20 _poolToken) external view returns (uint256);

    function incSystemBalance(IERC20 _poolToken, uint256 _poolAmount) external;

    function decSystemBalance(IERC20 _poolToken, uint256 _poolAmount) external;
}

