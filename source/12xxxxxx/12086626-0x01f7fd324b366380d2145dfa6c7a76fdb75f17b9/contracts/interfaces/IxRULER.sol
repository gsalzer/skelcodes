// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface IxRULER {
    event Deposit(address user, uint256 _ruler);
    event Withdraw(address, uint256 _shares, uint256 _ruler);

    struct Permit {
        address owner;
        address spender;
        uint256 amount;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    
    function getShareValue() external returns (uint256);
    function deposit(uint256 _amount) external;
    function depositWithPermit(uint256 _amount, Permit calldata permit) external;
    function withdraw(uint256 _amount) external;
    function collect(IERC20 _token) external;
}
