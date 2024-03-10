//////////////////////////////////////////////////
//SYNLEV price calculator proxy V 1.0.0
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';
import './priceCalculatorInterface.sol';

contract priceCalculatorProxy is Owned {

  priceCalculatorInterface public priceCalculator;
  address public priceCalculatorPropose;

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



  function proposePriceCalculator(address account) public onlyOwner() {
    priceCalculatorPropose = account;
  }
  function updatePriceCalculator() public {
    priceCalculator = priceCalculatorInterface(priceCalculatorPropose);
    priceCalculatorPropose = address(0);
  }

}

