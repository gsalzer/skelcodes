// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

abstract contract ERC677Receiver {
    function onTokenTransfer(
        address _from, 
        uint256 _amount, 
        bytes memory _data
    ) 
    public 
    virtual 
    returns(bool success);
}
