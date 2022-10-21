pragma solidity ^0.7.1;

import './SafeMath.sol';
import './ERC20Token.sol';
import './BlackList.sol';

/**
* @title Token that represents the stake in the ByteNext dividend fund
*/ 
contract BNUToken is ERC20Token, BlackList{
    using SafeMath for uint;

    uint internal _eightteenDecimalValue = 1000000000000000000;
    
    //TOKEN ALLOCATIONS
    address public _foundationalReserveAddress;
    address public _rewardsPoolAddress;
    address public _bnuStoreContractAddress;

    /**
     * @dev Generate token information
     * 1. Generate token information
     * 2. Transfer token for funds
     */
    constructor () {
        name = 'ByteNext';
        symbol = 'BNU';
        decimals = 18;
        _totalSupply = uint(200000000).mul(_eightteenDecimalValue);
        
        _foundationalReserveAddress = 0x219c2BF4C8DF6E05131A0f883b333ECd45bC64f6;
        _rewardsPoolAddress = 0x2E366a202e825606eb9158341D3856061BF26e62;
        _bnuStoreContractAddress = 0x4954e0062E0A7668A2FE3df924cD20E6440a7b77;
        
        //Transfer token to funds
        _balances[owner] = _totalSupply;
        _transfer(owner, _foundationalReserveAddress, uint(16000000).mul(_eightteenDecimalValue));          //16M
        _transfer(owner, _rewardsPoolAddress, uint(28439041).mul(_eightteenDecimalValue));                  //28,439,041
        _transfer(owner, _bnuStoreContractAddress, uint(155560959).mul(_eightteenDecimalValue));            //155,560,959 = 51,250,000 + 57,810,959 + 46,500,000
    }

    /**
    * @dev Transfer token `_value` to `_to`
    * 
    * Requirements
    *   Sender and receipent is not in black list
     */
    function transfer(address _to, uint _value) public override virtual contractActive returns(bool){
        require(!_isInBlackList(_msgSender()) && !_isInBlackList(_to), "Black account");
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
    * @dev Transfer token `amount` from `sender` to `recipient`
    * 
    * Requirements
    *   Sender and receipent is not in black list
    */
    function transferFrom(address sender, address recipient, uint amount) public virtual override contractActive returns(bool) {
        require(!_isInBlackList(sender) && !_isInBlackList(recipient), "Blocked account");
        return _transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
