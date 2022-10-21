// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

abstract contract ITransfer {
    function transfer(address _to, uint256 _value) public virtual returns (bool ok);
}

abstract contract IFreeUpTo {
    function freeUpTo(uint256 _value) public virtual returns (uint256 freed);
}

contract TestTransferer {
    IFreeUpTo constant private gst = IFreeUpTo(0x0000000000b3F879cb30FE243b4Dfee438691c04);
    
    modifier discount {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        gst.freeUpTo((gasSpent + 14154) / 41130);
    }
    
    constructor() discount {}

    function transfer(address token, address to, uint256 value) public discount {
        ITransfer(token).transfer(to, value);
    }
}
