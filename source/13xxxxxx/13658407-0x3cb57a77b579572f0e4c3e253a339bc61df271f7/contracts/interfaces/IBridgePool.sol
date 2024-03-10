// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBridgePool {
    function deposit(
        ERC20 token,
        uint amount,
        uint8 to,
        bool bonus,
        bytes calldata receiver
    ) external payable;

    function withdraw(
        bytes calldata id,
        ERC20 token,
        uint amount,
        uint bonus,
        address payable receiver,
        bytes calldata signature
    ) external;

    function take(ERC20 token, uint amount, address payable to) external;
}

