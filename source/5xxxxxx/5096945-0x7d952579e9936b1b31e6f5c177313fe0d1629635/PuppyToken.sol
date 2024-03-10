pragma solidity ^0.4.18;

/**
 * @title Crypto Puppy Token
 * @dev Standard ERC20 Token
 * @dev Developed by ExtremeSetup https://extremesetup.com/
 */


import './StandardToken.sol';
import './Ownable.sol';
contract PuppyToken is StandardToken, Ownable {
  string public name;
  string public symbol;
  uint public decimals;
  address public pupFundDeposit; 

  function PuppyToken() public{
    name = "CryptoPuppyToken";
    symbol = "PUP";
    decimals = 18;
    totalSupply_ = 300000000 * 10**uint(decimals);
    pupFundDeposit = 0xF52Bc5960BA0674bd91503EBF41Aaaa6765BD698; 
    balances[pupFundDeposit] = totalSupply_;
    Transfer(0x0, pupFundDeposit, totalSupply_);
  }
}

