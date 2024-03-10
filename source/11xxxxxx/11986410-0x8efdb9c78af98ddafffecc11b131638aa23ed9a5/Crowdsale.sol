pragma solidity ^0.4.24;

//import "../token/ERC20/ERC20.sol";
import "SafeMath.sol";
//import "../token/ERC20/SafeERC20.sol";


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  //using SafeERC20 for ERC20;

  // Address where funds are collected
  address public wallet;

  // Plants by ammount wei
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for plants purchase logging
   * @param purchaser who paid for the plants
   * @param beneficiary who got the plants
   * @param value weis paid for purchase
   * @param amount amount of plants purchased
   */
  event PlantPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of plants units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   */
  constructor(uint256 _rate, address _wallet) public {
    require(_rate > 0);
    require(_wallet != address(0));

    rate = _rate;
    wallet = _wallet;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyPlants(msg.sender);
  }

  /**
   * @dev low level plants purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the plant purchase
   */
  function buyPlants(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    // Validar antes de
    _preValidatePurchase(_beneficiary, weiAmount);
   
    // calculate plants amount to be created
    uint256 plants = _getPlantAmount(weiAmount);
    // update state
    weiRaised = weiRaised.add(weiAmount);

    //_processPurchase(_beneficiary, plants);

    emit PlantPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      plants
    );

    _updatePurchasingState(_beneficiary, weiAmount);
    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol's _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the plants purchase
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
   * @param _beneficiary Address performing the plants purchase
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
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the plants
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
   * @dev Override to extend the way in which ether is converted to plants.
   * @param _weiAmount Value in wei to be converted into plants
   * @return Number of plants that can be purchased with the specified _weiAmount
   */
  function _getPlantAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

