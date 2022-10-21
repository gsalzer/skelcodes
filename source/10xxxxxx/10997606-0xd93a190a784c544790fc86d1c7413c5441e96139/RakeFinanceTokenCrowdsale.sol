pragma solidity ^0.5.0;

import './RakeToken.sol';

contract RakeFinanceTokenCrowdsale {
     using SafeMath for uint256;
    
    /**
   * Event for RakeFinanceToken purchase logging
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

   bool public isEnded = false;

   event Ended(uint256 totalWeiRaisedInCrowdsale,uint256 unsoldTokensTransferredToOwner);
   
   uint256 public rate;     //Tokens per wei 
   address payable public ethBeneficiaryAccount;
   ERC20Burnable public RakeFinanceToken;
   
  // ICO Stage
  // ============
  enum CrowdsaleStage { PreICO, ICO }
  CrowdsaleStage public stage;      //0 for PreICO & 1 for ICO Stage
  // =============

  // RakeFinanceToken Distribution
  // =============================
  uint256 public totalTokensForSale = 5000*(1e18); // 5000 RAK will be sold during hole Crowdsale
  uint256 public totalTokensForSaleDuringPreICO = 2500*(1e18); // 2500 RAK will be sold during PreICO
  uint256 public totalTokensForSaleDuringICO = 2500*(1e18); // 2500 RAK will be sold during ICO
  // ==============================

  // Amount of wei raised in Crowdsale
  // ==================
  uint256 public totalWeiRaisedDuringPreICO;
  uint256 public totalWeiRaisedDuringICO;
  // ===================

  // RakeFinanceToken Amount remaining to Purchase
  // ==================
  uint256 public tokenRemainingForSaleInPreICO = 2500*(1e18);
  uint256 public tokenRemainingForSaleInICO = 2500*(1e18);
  // ===================


  // Events
  event EthTransferred(string text);
  
  //Modifier
    address public owner;    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

  // Constructor
  // ============
  constructor(uint256 initialRate,address payable wallet) public
  {   
      ethBeneficiaryAccount = wallet;
      setCurrentRate(initialRate);
      owner = msg.sender;
      stage = CrowdsaleStage.PreICO; // By default it's PreICO
      RakeFinanceToken = new RakeToken(owner); // RakeFinanceToken Deployment
  }
  // =============

  // Crowdsale Stage Management
  // =========================================================

  // Change Crowdsale Stage. Available Options: PreICO, ICO
  function switchToICOStage() public onlyOwner {
      require(stage == CrowdsaleStage.PreICO);
      stage = CrowdsaleStage.ICO;
      setCurrentRate(5);
  }

  // Change the current rate
  function setCurrentRate(uint256 _rate) private {
      rate = _rate;                     
  }

  // ================ Stage Management Over =====================
  
   /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the RakeFinanceToken purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal pure
  {
    require(_beneficiary != address(0));
    require(_weiAmount >= 1e17 wei,"Minimum amount to invest: 0.1 ETH");
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the RakeFinanceToken purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    RakeFinanceToken.transfer(_beneficiary, _tokenAmount);
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
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    ethBeneficiaryAccount.transfer(msg.value);
    emit EthTransferred("Forwarding funds to ETH Beneficiary Account");
  }
  
  // RakeFinanceToken Purchase
  // =========================
  function() external payable{
      if(isEnded){
          revert(); //Block Incoming ETH Deposits if Crowdsale has ended
      }
      buyRAKToken(msg.sender);
  }
  
  function buyRAKToken(address _beneficiary) public payable {
      uint256 weiAmount = msg.value;
      if(isEnded){
        revert();
      }
      _preValidatePurchase(_beneficiary, weiAmount);
      uint256 tokensToBePurchased = weiAmount.mul(rate);
      if ((stage == CrowdsaleStage.PreICO) && (tokensToBePurchased > tokenRemainingForSaleInPreICO)) {
         revert();  //Block Incoming ETH Deposits for PreICO stage if tokens to be purchased, exceeds remaining tokens for sale in Pre ICO
      }
      
      else if ((stage == CrowdsaleStage.ICO) && (tokensToBePurchased > tokenRemainingForSaleInICO)) {
        revert();  //Block Incoming ETH Deposits for ICO stage if tokens to be purchased, exceeds remaining tokens for sale in ICO
      }
      
       // calculate RakeFinanceToken amount to be created
       uint256 tokens = _getTokenAmount(weiAmount);
        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(
          msg.sender,
          _beneficiary,
          weiAmount,
          tokens
        );
        
      _forwardFunds();
      
      if (stage == CrowdsaleStage.PreICO) {
          totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(weiAmount);
          tokenRemainingForSaleInPreICO = tokenRemainingForSaleInPreICO.sub(tokensToBePurchased);
          if(tokenRemainingForSaleInPreICO == 0){       // Switch to ICO Stage when all tokens allocated for PreICO stage are being sold out
              switchToICOStage();
          }
      }
      else if (stage == CrowdsaleStage.ICO) {
          totalWeiRaisedDuringICO = totalWeiRaisedDuringICO.add(weiAmount);
          tokenRemainingForSaleInICO = tokenRemainingForSaleInICO.sub(tokensToBePurchased);
          if(tokenRemainingForSaleInICO == 0 && tokenRemainingForSaleInPreICO == 0){       // End Crowdsale when all tokens allocated for For Sale are being sold out
              endCrowdsale();
          }
      }
  }
  
  // Finish: Finalizing the Crowdsale.
  // ====================================================================

  function endCrowdsale() public onlyOwner {
      require(!isEnded && stage == CrowdsaleStage.ICO,"Should be at ICO Stage to Finalize the Crowdsale");
      uint256 unsoldTokens = tokenRemainingForSaleInPreICO.add(tokenRemainingForSaleInICO);
      if (unsoldTokens > 0) {
          tokenRemainingForSaleInICO = 0;
          tokenRemainingForSaleInPreICO = 0;
          RakeFinanceToken.transfer(owner,unsoldTokens);
      }
      emit Ended(totalWeiRaised(),unsoldTokens);
      isEnded = true;
  }
  // ===============================
    
    function balanceOf(address tokenHolder) external view returns(uint256 balance){
        return RakeFinanceToken.balanceOf(tokenHolder);
    }
    
    function totalWeiRaised() public view returns(uint256){
        return totalWeiRaisedDuringPreICO.add(totalWeiRaisedDuringICO);
    }
    
}
