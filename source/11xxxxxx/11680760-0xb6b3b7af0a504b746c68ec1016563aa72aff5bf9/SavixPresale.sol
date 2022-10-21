//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./IERC20.sol";

contract SavixPresale
{
  string private constant NAME = "SavixPresale";

  address private _owner;
  
  IERC20 private _token;

  bool private _isActive = false;
  bool private _isFinished = false;

  uint256 private _startDate;
  
   mapping(address => uint256) private _contributions;

  // Amount of wei raised
  uint256 private _weiRaised;
  uint256 private _tokensSold;
  uint256 private _tokenUnlockDate;
  
  uint256 private constant MIN_CONTRIBUTION = 1 * 10**17; // 0.1 ETH
  uint256 private constant MAX_CONTRIBUTION = 15 * 10**18; // 15 ETH
  uint256 private constant TOKEN_RATE = 60; // svx per eth
  uint256 private constant PRESALE_TOKEN_AMOUNT = 70000 * 10**9; // 9 decimals
  
  constructor() public 
  {
      _owner = msg.sender;
  }

  modifier onlyOwner()
  {
    require(msg.sender == _owner, "Only Owner");
    _;
  }

  function getOwner() 
    external
    view 
    returns(address)
  {
      return _owner;
  }
  
  modifier mustBeActive()
  {
    require(_isActive == true, "Presale not active"); // presale must be active
    _;
  }

  function name() external pure returns (string memory) 
  {
      return NAME;
  }

  function isFinished() public view returns(bool)
  {
     return _isFinished;
  }

  function isActive() public view returns(bool)
  {
     return _isActive;
  }

  function getContributor(address addr) 
    external
    view 
    returns(bool, uint256)
  {
      return (true, _contributions[addr]);
  }

  function getVersion() 
    external 
    pure
    returns(uint16)
  {
    return 1;
  }
  
  /**
  * token: target token contract for sale
  */  
  function startPresale(IERC20 token) 
    external 
    onlyOwner
  {
      require(_isActive == false,"presale already active");
      require(_isFinished == false,"presale already finished");
      require(IERC20(token).balanceOf(address(this)) == PRESALE_TOKEN_AMOUNT , "missing presale tokens");
      _token = IERC20(token);
      _isActive = true;
      _startDate = now;
      _tokenUnlockDate = _startDate + 180 days;
  }
  
  function endPresale(address payable ethWallet) 
    external
    onlyOwner
  {
      _isActive = false;
      _isFinished = true;
      // send contributions to target wallet
      ethWallet.transfer(payable(address(this)).balance);
  }

  function unlockRemainingTokens() 
    external 
    onlyOwner
  {
      require(now >= _tokenUnlockDate, "Tokens still locked");
      uint256 balance = _token.balanceOf(address(this));
      _token.transfer(msg.sender, balance);
  }

  function getTokenUnlockDate()
    external
    view
    returns(uint256)
  {
    return _tokenUnlockDate;
  }
  
  function getContributions() external view returns(uint256)
  {
      return _weiRaised;
  }

  function getEthBalance() external view returns(uint256)
  {
    return payable(address(this)).balance;
  }

  function getMinContribution() external pure returns(uint256)
  {
    return MIN_CONTRIBUTION;
  }

  function getMaxContribution() external pure returns(uint256)
  {
    return MAX_CONTRIBUTION;
  }

  function getTokenRate() external pure returns(uint256)
  {
    return TOKEN_RATE;
  }

  function getTokensLeftForSale() external view returns(uint256)
  {
    if(_isActive == false || _isFinished == true)
      return 0;

    return _token.balanceOf(address(this));
  }  

  function getMaxTokensForSale() external pure returns(uint256)
  {
      return PRESALE_TOKEN_AMOUNT;
  }   

  function getTokensSold() external view returns(uint256)
  {
    return _tokensSold;
  }

  receive() external payable mustBeActive
  { 
      require(msg.sender != address(0));
      require(msg.value != 0);
    
      // add the amount already contributed for the max contribution check
      // sender can contribute multiple times until max contribution limit
      uint256 fullValue = msg.value + _contributions[msg.sender];
    
      // must be within contribution window
      require(fullValue >= MIN_CONTRIBUTION && fullValue <= MAX_CONTRIBUTION, "Not within contribution window"); 
    
      // safemath needed here ? msg.value can be max of 15*10**18
      uint256 tokensToSend = (msg.value * TOKEN_RATE) / 10**9;

      // able to send this amount ?
      require(_token.balanceOf(address(this)) >= tokensToSend, "Out of tokens"); 
    
      // send tokens from _tokenWallet
      // the aproved token amount equals the presale token amount
      _token.transfer(msg.sender, tokensToSend);
    
      // adjust contributors contribution
      _contributions[msg.sender] += msg.value;
    
      // keeping track ourself for safety reasons. _weiRaised should always equal address(this).balance
      // alwso _weiRaised stays after eth got transferred out.
      _weiRaised += msg.value;
      _tokensSold += tokensToSend;
  }
}

