// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

contract Events {

    event TranscFeeClaimed(
        address indexed tokenHolderAddress,
        uint256 griseWeek,
        uint256 claimedAmount
    );
}
