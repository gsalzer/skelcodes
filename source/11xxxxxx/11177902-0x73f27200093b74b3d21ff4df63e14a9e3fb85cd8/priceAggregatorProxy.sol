//////////////////////////////////////////////////
//SYNLEV price aggregator proxy contract V 1.0.0
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';
import './priceAggregatorInterface.sol';

contract priceAggregatorProxy is Owned {

  priceAggregatorInterface public priceAggregator;
  address public priceAggregatorPropose;

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


  function proposeVaultPriceAggregator(address account) public onlyOwner() {
    priceAggregatorPropose = account;
  }
  function updateVaultAggregator() public {
    priceAggregator = priceAggregatorInterface(priceAggregatorPropose);
    priceAggregatorPropose = address(0);
  }

}

