//////////////////////////////////////////////////
//SYNLEV Vault Helper contract V 1.1
//////////////////////////

pragma solidity >= 0.6.4;

import './ownable.sol';
import './vaultHelperInterface.sol';

contract vaultHelperProxy is Owned {

  constructor() public {
    proposeDelay = 1;
    vaultHelper = vaultHelperInterface(0x4A754941ccE5e611Bc89C77F2Dd684c420acC5D0);
  }

  vaultHelperInterface public vaultHelper;
  address public vaultHelperPropose;
  uint256 public vaultHelperProposeTimestamp;

  uint256 public proposeDelay;
  uint256 public proposeDelayPropose;
  uint256 public proposeDelayTimestamp;

  function getBonus(address vault, address token, uint256 eth)
  public
  view
  virtual
  returns(uint256) {
    return(vaultHelper.getBonus(vault, token, eth));
  }

  function getPenalty(address vault, address token, uint256 eth)
  public
  view
  virtual
  returns(uint256) {
    return(vaultHelper.getPenalty(vault, token, eth));
  }

  function getSharePrice(address vault)
  public
  view
  virtual
  returns(uint256) {
    return(vaultHelper.getSharePrice(vault));
  }

  function getLiqAddTokens(address vault, uint256 eth)
  public
  view
  virtual
  returns(
    uint256 bullEquity,
    uint256 bearEquity,
    uint256 bullTokens,
    uint256 bearTokens
  ) {
    return(vaultHelper.getLiqAddTokens(vault, eth));
  }

  function getLiqRemoveTokens(address vault, uint256 eth)
  public
  view
  virtual
  returns(
    uint256 bullEquity,
    uint256 bearEquity,
    uint256 bullTokens,
    uint256 bearTokens,
    uint256 feesPaid
  ) {
    return(vaultHelper.getLiqRemoveTokens(vault, eth));
  }

  function proposeVaultHelper(address account) public onlyOwner() {
    vaultHelperPropose = account;
    vaultHelperProposeTimestamp = block.timestamp;
  }
  function updateVaultHelper() public onlyOwner() {
    require(vaultHelperPropose != address(0));
    require(vaultHelperProposeTimestamp + proposeDelay <= block.timestamp);
    vaultHelper = vaultHelperInterface(vaultHelperPropose);
    vaultHelperPropose = address(0);
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

