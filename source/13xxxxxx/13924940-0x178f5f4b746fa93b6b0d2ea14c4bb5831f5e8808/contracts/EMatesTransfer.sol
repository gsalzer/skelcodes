// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IEMates.sol";

contract EMatesTransfer is Ownable {
    IEMates public immutable emates;

    constructor(
        IEMates _emates
    ) {
        emates = _emates;
    }

    function transfer(address to, uint256[] calldata ids) external {
        uint256 length = ids.length;
        for (uint256 i = 0; i < length; i += 1) {
            emates.transferFrom(msg.sender, to, ids[i]);
        }
    }
}

