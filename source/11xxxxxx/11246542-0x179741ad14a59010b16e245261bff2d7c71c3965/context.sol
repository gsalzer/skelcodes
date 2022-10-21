// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
abstract contract Context {
    function _sender() public view virtual returns (address payable) {
        return msg.sender;
    }
}
