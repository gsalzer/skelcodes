pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";


/**
 * @title FavorCoinCrowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropiate to concatenate
 * behavior.
 */
contract FavorCoinCrowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address payable public wallet;

  // How many token units a buyer gets per wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;
  
  uint256 public FEE = 1;
  
  uint256 public tokensSold;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event FeeUpdated(uint256 newFee);
    
    event Deposit(address indexed from, uint256 value);
  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address payable  _wallet, address _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = ERC20(_token);
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address payable  _beneficiary) public payable {
    require(msg.value != 0);
    uint256 amountTobuy = msg.value;
    uint256 dexBalance = token.balanceOf(address(this));
    require(amountTobuy > 0, "You need to send some ether");
    
     _preValidatePurchase(_beneficiary, amountTobuy);
    uint256 _fee = SafeMath.wdiv((SafeMath.wmul(amountTobuy,FEE)),1000);
    uint256 _amountTobuy = SafeMath.sub(amountTobuy,_fee);
     
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(_amountTobuy);
    require(tokens <= dexBalance, "Not enough tokens in the reserve");
 
    tokensSold = tokensSold.add(tokens);
    // update state
    weiRaised = weiRaised.add(amountTobuy);
    emit Deposit(_beneficiary,tokens);
    ERC20(token).transfer(address(_beneficiary), tokens);
    emit Transfer(address(0),_beneficiary,tokens);
    
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      amountTobuy,
      tokens
    );
    

    _updatePurchasingState(_beneficiary, amountTobuy);
    
     (bool success, bytes memory mem) = address(wallet).call.value(msg.value).gas(21000)('');
        require(success);
        
  
    _postValidatePurchase(_beneficiary, amountTobuy);
  }
  
  function sendEther(address payable receiverAddr, uint256 _amount)  external onlyOwner {
      if (!address(receiverAddr).send(_amount)) {
          revert();
      }
  }

  function sendETHMasterWallet(uint256 _amount) external onlyOwner {
      (bool success, bytes memory mem) = address(wallet).call.value(_amount).gas(21000)('');
        require(success);
  }

 function setFee(uint _fee) external onlyOwner{
        FEE = _fee;
        emit FeeUpdated(FEE);
    }
function setWallet(address payable _wallet) external onlyOwner{
    wallet = _wallet;
    emit FeeUpdated(FEE);
}
  function tokensRemaining() public view returns (uint256){
      return token.balanceOf(address(this));
  }
  

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.div(rate);
  }

  
}

