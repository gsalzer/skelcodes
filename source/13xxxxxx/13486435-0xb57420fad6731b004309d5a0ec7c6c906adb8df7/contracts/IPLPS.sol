// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IPLPS {
    function LiquidityProtection_beforeTokenTransfer(
        address _pool, address _from, address _to, uint _amount) external;
    function isBlocked(address _pool, address _who) external view returns(bool);
    function unblock(address _pool, address[] calldata _whos) external;
}

