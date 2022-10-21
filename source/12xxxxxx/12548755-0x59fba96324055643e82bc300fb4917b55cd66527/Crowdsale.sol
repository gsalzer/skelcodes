// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

import './IStdReference.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IStdReference public _ref;

    // The token being sold
    IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;

    uint256 private _rate; 

    uint256 private _price;

    uint256 private _cap;


    // Amount of wei raised
    uint256 private _weiRaised;

    // Amount of tokens sold;
    uint256 private _tokensSold;
    
    // Opening time of the ICO
    uint256 private _openingTime;

    // Closing time of the ICO
    uint256 private _closingTime;


    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor(
        IStdReference ref,
        uint256 price,
        uint256 cap,
        address payable wallet,
        uint256 openingTime,
        uint256 closingTime
    ) {
                
        //require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");
        require(price > 0, "Crowdsale: price is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        _cap = cap;
        _ref = ref;
        _price = price;
        _wallet = wallet;
        _openingTime = openingTime;
        _closingTime = closingTime;

        _updateRate();
    }
   
    function initSale(
        IERC20 crowdsaleToken
    ) public onlyOwner {
        require(address(_token) == address(0), "Crowdsale: token is already set.");
        require(crowdsaleToken.balanceOf(address(this)) != 0, 'Crowdsale: contract has no tokenbalance');
    
        _token = crowdsaleToken;

        _updateRate();

    }

    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
    receive() external payable {
        buyTokens(_msgSender());
    }

   

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    function ethPrice() public view returns (uint256) {
        return _fetchPrice('ETH', 'USD');
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the token being sold.
     */
    function price() public view returns (uint256) {
        return _price;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @return the amount of wei raised.
     */
    function tokensSold() public view returns (uint256) {
        return _tokensSold;
    }

    /**
     * @return the crowdsale opening time.
     */
    function openingTime() public view returns (uint256) {
        return _openingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    function tokensLeft() public view returns (uint256) {
        return _getLeftoverTokens();
    }

    /**
     * @return true if the crowdsale is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    function weiAmount(uint256 tokenAmountIn) public view returns(uint256) {
        return _getWeiAmount(tokenAmountIn);
    }

    function tokenAmount(uint256 weiAmountIn ) public view returns(uint256) {
        return _getTokenAmount(weiAmountIn);
    }


    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public nonReentrant payable {
        _updateRate();

        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _tokensSold = _tokensSold.add(tokens);
        _weiRaised = _weiRaised.add(weiAmount);

        require(_tokensSold <= _cap, 'Crowdsale: Can not buy more tokens then the capped amount');

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    function startNewSale(
        uint256 price,
        uint256 amountToBeSold,
        uint256 openingTime,
        uint256 closingTime
    ) public onlyOwner {
        require(hasClosed() == true, "TimedCrowdsale: Prev stage hasnt closed yet");
        require(openingTime >= block.timestamp, "TimedCrowdsale: opening time is before current time");
        require(closingTime > openingTime, "TimedCrowdsale: opening time is not before closing time");
        require(price > 0, "Crowdsale: price is 0");
        require(_token.balanceOf(address(this)) >= amountToBeSold, 'Crowdsale: amountToBeSold is to big');
        _price = price;
        _cap = amountToBeSold.add(_cap);
        _openingTime = openingTime;
        _closingTime = closingTime;
        _updateRate();

    }


    function changePrice(uint256 newPrice) public onlyOwner {
        require(hasClosed() == true, 'Crowdsale: Can not change price when sale is open');
        _price = newPrice;

    }

    function _updateRate() internal {
        uint256 ethPrice = ethPrice();

       _rate =  _calculateRate(ethPrice, _price);
    }


    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.transfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate);
    }

    /**
     * @param tokenAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getWeiAmount(uint256 tokenAmount) internal view returns (uint256) {
        return tokenAmount.div(_rate);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getLeftoverTokens() internal view returns (uint256) {
        return _cap.sub(_tokensSold);
    }

   

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }

    /**
     * @dev Gets the price from the BAND oracle contract.
     */
    function _fetchPrice(string memory base, string memory quote) internal view returns (uint256){
        IStdReference.ReferenceData memory data = _ref.getReferenceData(base, quote);
        return data.rate;
    }

    function _calculateRate(uint256 ethPrice, uint256 tokenPrice) internal view returns (uint256) {
        return ethPrice.div(tokenPrice); 
    }


    /**
     * @dev Reverts if not in crowdsale time range.
     */
    modifier onlyWhileOpen {
        require(isOpen(), "TimedCrowdsale: not open");
        _;
    }

  
}

