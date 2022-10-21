// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

interface IVokenAudit {
    function getAccount(address account) external view
        returns (
            uint72 wei_purchased,
            uint72 wei_rewarded,
            uint72 wei_audit,
            uint16 txs_in,
            uint16 txs_out
        );
}

