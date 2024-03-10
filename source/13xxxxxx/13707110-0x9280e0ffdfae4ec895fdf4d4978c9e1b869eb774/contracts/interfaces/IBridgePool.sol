// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBridgePool {
    struct Withdraw {
        bytes32 id;
        IERC20 token;
        uint amount;
        uint bonus;
        address payable recipient;
    }

    event Deposited(address indexed sender, address indexed token, uint8 indexed to, uint amount, bool bonus, bytes recipient);
    event Withdrawn(bytes32 indexed id, address indexed token, address indexed recipient, uint amount);

    function operator(address account) external view returns (uint8 mode);
    function deposit(IERC20 token, uint amount, uint8 to, bool bonus, bytes calldata recipient ) external payable;
    function withdraw(Withdraw[] memory ws) external;
    function take(IERC20 token, uint amount, address payable to) external;
}

