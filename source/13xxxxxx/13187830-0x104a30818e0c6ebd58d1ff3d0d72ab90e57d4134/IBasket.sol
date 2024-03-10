// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IBasket {
    function transfer(address dst, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function mint(uint256) external;

    function getOne() external view returns (address[] memory, uint256[] memory);

    function getAssetsAndBalances() external view returns (address[] memory, uint256[] memory);

    function burn(uint256) external;

    function viewMint(uint256 _amountOut) external view returns (uint256[] memory _amountsIn);
}

