// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC20.sol";

abstract contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function getStuckedEth() public onlyOwner {
        uint256 ethBalance = address(this).balance;

        if (ethBalance > 0) {
            payable(msg.sender).transfer(ethBalance);
        }
    }

    function getStuckedErc(address token) public onlyOwner {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (tokenBalance > 0) {
            IERC20(token).transfer(msg.sender, tokenBalance);
        }
    }
}

