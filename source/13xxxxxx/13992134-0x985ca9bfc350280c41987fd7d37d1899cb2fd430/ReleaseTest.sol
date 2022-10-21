// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ReleaseTest {
    event WasReleased(address sender);

    function release() external {
        emit WasReleased(msg.sender);
    }
}
