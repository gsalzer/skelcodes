//////////////////////////////////////////////////
//SYNLEV price calculator proxy V 1.1
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';
import './priceCalculatorInterface.sol';

contract priceCalculatorProxy is Owned {

  constructor() public {
    proposeDelay = 1;
  }

  priceCalculatorInterface public priceCalculator;
  address public priceCalculatorPropose;
  uint256 public priceCalculatorProposeTimestamp;

  uint256 public proposeDelay;
  uint256 public proposeDelayPropose;
  uint256 public proposeDelayTimestamp;

  function getUpdatedPrice(address vault, uint256 latestRoundId)
  public
  view
  virtual
  returns(
    uint256[6] memory latestPrice,
    uint256 rRoundId,
    bool updated
  ) {
    return(priceCalculator.getUpdatedPrice(vault, latestRoundId));
  }

  //Admin Functions
  function proposePriceCalculator(address account) public onlyOwner() {
    priceCalculatorPropose = account;
    priceCalculatorProposeTimestamp = block.timestamp;
  }
  function updatePriceCalculator() public onlyOwner() {
    require(priceCalculatorPropose != address(0));
    require(priceCalculatorProposeTimestamp + proposeDelay <= block.timestamp);
    priceCalculator = priceCalculatorInterface(priceCalculatorPropose);
    priceCalculatorPropose = address(0);
  }

  function proposeProposeDelay(uint256 delay) public onlyOwner() {
    proposeDelayPropose = delay;
    proposeDelayTimestamp = block.timestamp;
  }
  function updateProposeDelay() public onlyOwner() {
    require(proposeDelayPropose != 0);
    require(proposeDelayTimestamp + proposeDelay <= block.timestamp);
    proposeDelay = proposeDelayPropose;
    proposeDelayPropose = 0;
  }
}

