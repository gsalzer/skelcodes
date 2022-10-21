// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IMultiERC20Handler {

    function registerERC20Token(address value) external;

    function removeERC20Token(uint256 key) external;

    function isValidToken(address value) external view returns (bool);

    function isValidSymbol(string memory symbol) external view returns (bool);

    function isValidSymbols(string[] memory symbols) external view returns (bool);

    function ERC20TokensContainsKey(uint256 key) external view returns (bool);

    function ERC20TokensLength() external view returns (uint256);

    function ERC20TokensAt(uint256 index) external view returns (uint256 key, address value);

    function tryGetERC20Token(uint256 key) external view returns (bool, address);

    function getERC20Token(uint256 key) external view returns (address);

    function getERC20TokenWithMessage(uint256 key, string calldata errorMessage) external view returns (address);

    function symbolToIERC20(string memory symbol) external view returns (IERC20);

    function symbolToAddress(string memory symbol) external view returns (address);

    function getAllSymbols() external view returns (string[] memory);

    function getCurrentKeys() external view returns (uint256[] memory);
}

