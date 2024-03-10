// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface IBasket {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function mint(uint256) external;

    function getOne() external view returns (address[] memory, uint256[] memory);

    function getAssetsAndBalances() external view returns (address[] memory, uint256[] memory);

    function burn(uint256) external;

    function execute(address _module, bytes memory _data) external payable returns (bytes memory response);

    function grantRole(bytes32, address) external;

    function MARKET_MAKER() external view returns (bytes32);
}

