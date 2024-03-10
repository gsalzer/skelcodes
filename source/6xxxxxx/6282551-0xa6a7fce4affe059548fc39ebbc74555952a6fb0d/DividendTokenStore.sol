pragma solidity ^0.4.24;

import './Pausable.sol';

contract DividendTokenStore is Pausable {

  function totalSupply() public view returns (uint256);

  function addLock(address _locked) public returns (bool);

  function revokeLock(address _unlocked) public returns (bool);
  
  function balanceOf(address _owner) public view returns (uint256);

  function transfer(address _from, address _to, uint256 _value) public returns (bool);
  
  function () public payable {
    payIn();
  }

  function payIn() public payable returns (bool);
  
  function claimDividends() public returns (uint256);
  
  function claimDividendsFor(address _address) public returns (uint256);
    
  function buyBack() public payable returns (bool);

  function claimBuyBack() public returns (bool);

  function claimBuyBackFor(address _address) public returns (bool);

  function mint(address _to, uint256 _amount) public returns (bool);
  
  event Paid(address indexed _sender, uint256 indexed _period, uint256 amount);

  event Claimed(address indexed _recipient, uint256 indexed _period, uint256 _amount);

  event Locked(address indexed _locked, uint256 indexed _at);

  event Unlocked(address indexed _unlocked, uint256 indexed _at);
}

