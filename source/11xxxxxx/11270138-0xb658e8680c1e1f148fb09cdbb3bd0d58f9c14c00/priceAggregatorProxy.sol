//////////////////////////////////////////////////
//SYNLEV price aggregator proxy contract V 1.1
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';
import './priceAggregatorInterface.sol';

contract priceAggregatorProxy is Owned {

  constructor() public {
    proposeDelay = 1;
    priceAggregator = priceAggregatorInterface(0x7196545d854D03D9c87B7588F6D9e1e42D876E95);
  }

  priceAggregatorInterface public priceAggregator;
  address public priceAggregatorPropose;
  uint256 public priceAggregatorProposeTimestamp;

  uint256 public proposeDelay;
  uint256 public proposeDelayPropose;
  uint256 public proposeDelayTimestamp;

  function priceRequest(address vault, uint256 lastUpdated)
  public
  view
  virtual
  returns(int256[] memory, uint256) {

    (int256[] memory priceData, uint256 roundID) =
    priceAggregator.priceRequest(vault, lastUpdated);

    return(priceData, roundID);
  }

  function roundIdCheck(address vault) public view returns(bool) {
    return(priceAggregator.roundIdCheck(vault));
  }

  //Admin Functions
  function proposeVaultPriceAggregator(address account) public onlyOwner() {
    priceAggregatorPropose = account;
    priceAggregatorProposeTimestamp = block.timestamp;
  }
  function updateVaultPriceAggregator() public onlyOwner() {
    require(priceAggregatorPropose != address(0));
    require(priceAggregatorProposeTimestamp + proposeDelay <= block.timestamp);
    priceAggregator = priceAggregatorInterface(priceAggregatorPropose);
    priceAggregatorPropose = address(0);
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

