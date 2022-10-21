// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./Permissions.sol";

contract Treasury is Permissions {
    constructor() public Permissions() {
    }

    receive () external payable {
    }

    function withdrawETH(address payable receipient, uint amount) external onlyGovernor {
        receipient.transfer(amount); 
    }

    function withdrawToken(address token, address receipient, uint amount) external onlyGovernor {
        IERC20(token).transfer(receipient, amount);
    }
}
