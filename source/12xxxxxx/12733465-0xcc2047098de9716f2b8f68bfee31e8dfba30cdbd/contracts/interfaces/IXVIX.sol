// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IXVIX {
    function setGov(address gov) external;
    function createSafe(address account) external;
    function normalDivisor() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function toast(uint256 amount) external returns (bool);
    function rebase() external returns (bool);
}

