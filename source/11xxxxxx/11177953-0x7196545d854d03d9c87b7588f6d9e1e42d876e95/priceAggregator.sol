//////////////////////////////////////////////////
//SYNLEV PRICE AGGREGATOR CONTRACT V 1.0.0
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './AggregatorInterface.sol';
import './vaultInterface.sol';

contract priceAggregator is Owned {
  using SafeMath for uint256;

  constructor() public {

  }

  struct vaultStruct{
    AggregatorInterface ref;
  }

  mapping(address => vaultStruct) public refVault;     //Vault address => vaultStruct

  uint256 public maxUpdates = 50;

  function priceRequest(address vault, uint256 lastUpdated)
  public
  view
  returns(int256[] memory, uint256)
  {
    uint256 currentRound = refVault[vault].ref.latestRound();
    if(currentRound > lastUpdated) {
      uint256 pricearrayLength = currentRound.add(1).sub(lastUpdated);
      pricearrayLength = pricearrayLength > maxUpdates ?
      maxUpdates : pricearrayLength;
      int256[] memory pricearray = new int256[] (pricearrayLength);
      pricearray[0] = refVault[vault].ref.getAnswer(lastUpdated);
      for(uint i = 1; i < pricearrayLength; i++) {
        pricearray[pricearrayLength.sub(i)] =
        refVault[vault].ref.getAnswer(currentRound.add(1).sub(i));
      }
      return(pricearray, currentRound);
    }
    else {
      return(new int256[](0), currentRound);
    }
  }

  /*
   * @notice Returns false if the price is not updated on vault.
  */

  function roundIdCheck(address vault) public view returns(bool) {
    if(vaultInterface(vault).getLatestRoundId()
    < refVault[vault].ref.latestRound()) {
      return(false);
    }
    else return(true);
  }


  function setMaxUpdates(uint256 amount) public onlyOwner() {
    require(amount > 1);
    maxUpdates = amount;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  //Functions setting and updating vault
  //to chainlink aggregator contract connections
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

  //Can only be called by vault proxy, initiates pair
  function registerVaultAggregator(address aggregator) public {
    refVault[msg.sender].ref = AggregatorInterface(aggregator);
  }
}

