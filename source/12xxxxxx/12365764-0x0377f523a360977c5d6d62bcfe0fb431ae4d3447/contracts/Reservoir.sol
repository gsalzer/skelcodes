// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Reservoir is Ownable {
    constructor() Ownable() {}

    function setApprove(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).approve(_to, _amount);
    }

    function withdrawEmergency(address _token) external onlyOwner {
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }
}

