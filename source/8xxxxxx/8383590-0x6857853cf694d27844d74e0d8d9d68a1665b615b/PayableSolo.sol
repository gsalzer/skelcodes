pragma solidity ^0.4.11;

import "./OwnableSolo.sol";

contract PayableSolo is OwnableSolo {
    
    //@dev withdraws any funds available on the contract, only the owner of the contract can withdraw funds
    function withdraw() onlyOwner public  {
        msg.sender.transfer(this.balance);  //change above to "(address(contract).balance)"
                          
    }

    //@dev deposits ETH to contract
    //@parm amount the amount being deposited
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        
    }

    //@dev returns the total balance of ETH on the contract
    function getBalance() public view returns (uint256) {
        return this.balance; //changed this to "return address(contract).balance;"
    } 
}

// The MIT License (MIT)

// Copyright (c) 2016 Smart Contract Solutions, Inc.

// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:

// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
// IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
// CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
// TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
// © 2018 GitHub, Inc.
