// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibBaseAuth.sol";


contract WithDeadline is BaseAuth {
    uint256 private _deadlineTimestamp;

    constructor ()
    {
        _deadlineTimestamp = 1617235199;  // Wed, 31 Mar 2021 23:59:59 +0000
    }

    modifier onlyBeforeDeadline()
    {
        require(block.timestamp <= _deadlineTimestamp, "later than deadline");
        _;
    }

    function setDeadline(
        uint256 deadlineTimestamp
    )
        external
        onlyAgent
    {
        _deadlineTimestamp = deadlineTimestamp;
    }

    function _deadline()
        internal
        view
        returns (uint256)
    {
        return _deadlineTimestamp;
    }
}

