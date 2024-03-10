// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/access/Ownable.sol";
import "./@openzeppelin/contracts/contracts/token/ERC1155/IERC1155.sol";
import "./IFeeV2.sol";

contract FeeFixedV2 is IFeeV2, Ownable {
    uint256 public fee;

    constructor(uint256 fee_) {
        setFee(fee_);
    }

    function setFee(uint256 fee_) public onlyOwner {
        fee = fee_;
    }

    function calculate(address, uint256) public view override returns (uint256) {
        return fee;
    }
}

