// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Lunadoge} from "./Lunadoge.sol";

contract Controller is Ownable {
    using SafeERC20 for IERC20;

    address public ldoge;

    constructor(address _ldoge) {
        ldoge = _ldoge;
    }

    function setFee(uint256 _fee) public onlyOwner {
        Lunadoge(ldoge).setFee(_fee);
    }

    function lunchtime() public onlyOwner {
        Lunadoge(ldoge).lunchtime();
        IERC20 token = IERC20(Lunadoge(ldoge).luna());
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }
}

