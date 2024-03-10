//////////////////////////////////////////////////
//SYNLEV PRICE AGGREGATOR CONTRACT V 1.3
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './SignedSafeMath.sol';
import './AggregatorV2V3Interface.sol';
import './vaultInterface.sol';

contract priceAggregator is Owned {
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  constructor() public {
    standardUpdateWindow = 10;
    refVault[0xFf40827Ee1c4Eb6052044101E1C6E28DBe1440e3].ref =
      AggregatorV2V3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    refVault[0xA81f8460dE4008577e7e6a17708102392f9aD92D].ref =
      AggregatorV2V3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    refVault[0x19392DBeA0Cc2dE68c47D186903420F07d63917a].ref =
      AggregatorV2V3Interface(0xA027702dbb89fbd58938e4324ac03B58d812b0E1);

  }

  struct vaultStruct{
    AggregatorV2V3Interface ref;
    uint80 updateWindow;
  }

  mapping(address => vaultStruct) public refVault;     //Vault address => vaultStruct

  uint80 public standardUpdateWindow;

  function priceRequest(address vault, uint256 lastUpdated)
    public
    view
    returns(int256[] memory, uint256)
    {
      uint80 start = uint80(lastUpdated);
      vaultStruct memory rVault = refVault[vault];
      uint80 currentRound = uint80(rVault.ref.latestRound());
      if(currentRound > lastUpdated + 10**4) {
        int256[] memory pricearray = new int256[] (2);
        ( , pricearray[0], , , ) = rVault.ref.getRoundData(start);
        ( , pricearray[1], , , ) = rVault.ref.getRoundData(currentRound);
        return(pricearray, currentRound);
      }
      else if(currentRound > lastUpdated) {
        int256[] memory pricearray = new int256[] (2);
        uint80 updateWindow = rVault.updateWindow != 0 ? rVault.updateWindow : standardUpdateWindow;
        start = start < currentRound - updateWindow ? start : currentRound - updateWindow;
        ( , pricearray[0], , , ) = rVault.ref.getRoundData(start);
        int256 price;
        for(uint80 i = 1; i < updateWindow; i++) {
          ( , price, , , ) = rVault.ref.getRoundData(i + currentRound - updateWindow);
          pricearray[1] = pricearray[1].add(price);
        }
        pricearray[0] = pricearray[0].add(pricearray[1]);
        ( , price, , , ) = rVault.ref.getRoundData(currentRound);
        pricearray[1] = pricearray[1].add(price);
        pricearray[0] = pricearray[0].div(updateWindow);
        pricearray[1] = pricearray[1].div(updateWindow);
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

  function setUpdateWindow(uint80 amount, address vault) public onlyOwner() {
    require(amount >= 1);
    refVault[vault].updateWindow = amount;
  }

  function setStandardUpdateWindow(uint80 amount) public onlyOwner() {
    require(amount >= 1);
    standardUpdateWindow = amount;
  }

  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  //Functions setting and updating vault
  //to chainlink aggregator contract connections
  //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~//

  //Can only be called by vault proxy, initiates pair
  function registerVaultAggregator(address aggregator) public {
    refVault[msg.sender].ref = AggregatorV2V3Interface(aggregator);
  }
}

