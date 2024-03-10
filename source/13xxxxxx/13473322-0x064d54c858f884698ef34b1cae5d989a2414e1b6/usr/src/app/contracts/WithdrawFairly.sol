// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract WithdrawFairly is Ownable {
    using SafeMath for uint256;

    struct Part {
        address wallet;
        uint256 salePart;
        uint256 royaltiesPart;
    }

    Part[] public parts;

    constructor(){
        parts.push(Part(0x764789dF2592764EeF2408E9524C4eCadDCb31C9, 50, 0)); // creator
        parts.push(Part(0x8a73c4777163c467b2eee9cd6858B2A56D376B70, 0, 50)); // creator
        parts.push(Part(0xcBCc84766F2950CF867f42D766c43fB2D2Ba3256, 50, 50)); // dev
    }

    function withdrawSales() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Sales Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].salePart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].salePart).div(100));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function withdrawRoyalties() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Contract Balance = 0");

        for(uint8 i = 0; i < parts.length; i++){
            if(parts[i].royaltiesPart > 0){
                _withdraw(parts[i].wallet, balance.mul(parts[i].royaltiesPart).div(100));
            }
        }

        _withdraw(owner(), address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    receive() external payable {}

}
