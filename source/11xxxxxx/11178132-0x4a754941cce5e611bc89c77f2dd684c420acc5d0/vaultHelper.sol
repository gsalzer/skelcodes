//////////////////////////////////////////////////
//SYNLEV Vault Helper contract V 1.0.0
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './vaultInterface.sol';

contract vaultHelper is Owned {
  using SafeMath for uint256;

  constructor() public {
    balanceControlFactor = 10**9;
  }

  uint256 public balanceControlFactor;

  /*
   * @notice Returns the buy bonus based on the incoming ETH and selected token.
   * Only relevant to token buys
   * @param token The selected bull or bear token
   * @param eth The amount of ETH to be added
   * @return Bonus in ETH
   */
  function getBonus(address vault, address token, uint256 eth)
  public
  view
  returns(uint256)
  {
    vaultInterface ivault = vaultInterface(vault);
    //Grab total equity of both tokens
    uint256 totaleth0 = ivault.getTotalEquity();
    //Grab total equity of only target token
    uint256 tokeneth0 = ivault.getTokenEquity(token);
    uint256 balanceEquity = ivault.getBalanceEquity();
    //Check if we need to calc a bonus
    if(balanceEquity > 0 && totaleth0 > tokeneth0.mul(2)) {
      //Current ratio of token equity to total equity
      uint256 ratio0 = tokeneth0.mul(1 ether).div(totaleth0);
      //Ratio of token equity to total equity after buy
      uint256 ratio1 = tokeneth0.add(eth).mul(1 ether).div(totaleth0.add(eth));
      //If the after buy ratio is grater than .5 (50%) we reward the entire
      //balance equity
      return(
        ratio1 <= 5 * 10**17 ?
        ratio1.sub(ratio0).mul(1 ether).div(5 * 10**17 - ratio0).mul(balanceEquity).div(1 ether) :
        balanceEquity
      );
    }
    else {
      return(0);
    }
  }

  /*
   * @notice Returns the sell penalty based on the outgoing ETH and selected
   * token. Only relevant to token sells.
   * @param token The selected bull or bear token
   * @param eth The amount of outgoing ETH
   * @return Penalty in ETH
   */
  function getPenalty(address vault, address token, uint256 eth)
  public
  view
  returns(uint256)
  {
    vaultInterface ivault = vaultInterface(vault);
    //Grab total equity of both tokens
    uint256 totaleth0 = ivault.getTotalEquity();
    //Grab total equity of only target token
    uint256 tokeneth0 = ivault.getTokenEquity(token);
    //Calc target token equity after sell
    uint256 tokeneth1 = tokeneth0.sub(eth);
    //Only calc penalty if ratio is less than .5 (50%) after token sell
    if(totaleth0.div(2) >= tokeneth1) {
      //Current ratio of token equity to total equity
      uint256 ratio0 = tokeneth0.mul(1 ether).div(totaleth0);
      //Ratio of token equity to total equity after buy
      uint256 ratio1 = tokeneth1.mul(1 ether).div(totaleth0.sub(eth));
      return(balanceControlFactor.mul(ratio0.sub(ratio1).div(2)).mul(eth).div(10**9).div(1 ether));
    }
    else {
      return(0);
    }
  }

  /*
   * @notice Returns the current LP share price. Defaults to 1 ETH if 0 LP
   * @param token The selected bull or bear token
   * @param eth The amount of outgoing ETH
   * @return Penalty in ETH
   */
  function getSharePrice(address vault)
  public
  view
  returns(uint256)
  {
    vaultInterface ivault = vaultInterface(vault);
    address bull = ivault.getBullToken();
    address bear = ivault.getBearToken();
    if(ivault.getTotalLiqShares() == 0) {
      return(1 ether);
    }
    else {
      return(
        ivault.getLiqEquity(bull)
        .add(ivault.getLiqEquity(bear))
        .add(ivault.getLiqFees())
        .mul(1 ether)
        .div(ivault.getTotalLiqShares())
      );
    }
  }


  /*
   * @notice Calc how many bull/bear tokens virtually mint based on incoming
   * ETH.
   * @returns bull/bear equity and bull/bear tokens to be added
  */
  function getLiqAddTokens(address vault, uint256 eth)
  public
  view
  returns(uint256, uint256, uint256, uint256)
  {
    vaultInterface ivault = vaultInterface(vault);
    address bull = ivault.getBullToken();
    address bear = ivault.getBearToken();
    uint256 bullEquity = ivault.getLiqEquity(bull) < ivault.getLiqEquity(bear) ?
      ivault.getLiqEquity(bear).sub(ivault.getLiqEquity(bull)) : 0 ;
    uint256 bearEquity = ivault.getLiqEquity(bear) < ivault.getLiqEquity(bull) ?
      ivault.getLiqEquity(bull).sub(ivault.getLiqEquity(bear)) : 0 ;
    if(bullEquity >= eth) bullEquity = eth;
    else if(bearEquity >= eth) bearEquity = eth;
    else if(bullEquity > bearEquity) {
      bullEquity = bullEquity.add(eth.sub(bullEquity).div(2));
      bearEquity = eth.sub(bullEquity);
    }
    else if(bearEquity > bullEquity) {
      bearEquity = bearEquity.add(eth.sub(bearEquity).div(2));
      bullEquity = eth.sub(bearEquity);
    }
    else {
      bullEquity = eth.div(2);
      bearEquity = eth.sub(bullEquity);
    }
    return(
      bullEquity,
      bearEquity,
      bullEquity.mul(1 ether).div(ivault.getPrice(bull)),
      bearEquity.mul(1 ether).div(ivault.getPrice(bear))
    );
  }

  /*
   * @notice Calc how many bull/bear tokens virtually burn based on shares
   * being removed.
   * @param shares Amount of shares user removing from LP
   * @returns bull/bear equity and bull/bear tokens to be removed
  */
  function getLiqRemoveTokens(address vault, uint256 shares)
  public
  view
  returns(uint256, uint256, uint256, uint256, uint256)
  {
    vaultInterface ivault = vaultInterface(vault);
    address bull = ivault.getBullToken();
    address bear = ivault.getBearToken();
    uint256 eth =
      shares
      .mul(ivault.getLiqEquity(bull)
      .add(ivault.getLiqEquity(bear))
      .mul(1 ether).div(ivault.getTotalLiqShares()))
      .div(1 ether);
    uint256 bullEquity = ivault.getLiqEquity(bull) > ivault.getLiqEquity(bear) ?
      ivault.getLiqEquity(bull).sub(ivault.getLiqEquity(bear)) : 0 ;
    uint256 bearEquity = ivault.getLiqEquity(bear) > ivault.getLiqEquity(bull) ?
      ivault.getLiqEquity(bear).sub(ivault.getLiqEquity(bull)) : 0 ;
    if(bullEquity >= eth) bullEquity = eth;
    else if(bearEquity >= eth) bearEquity = eth;
    else if(bullEquity > bearEquity) {
      bullEquity = bullEquity.add(eth.sub(bullEquity).div(2));
      bearEquity = eth.sub(bullEquity);
    }
    else if(bearEquity > bullEquity) {
      bearEquity = bearEquity.add(eth.sub(bearEquity).div(2));
      bullEquity = eth.sub(bearEquity);
    }
    else {
      bullEquity = eth.div(2);
      bearEquity = eth.sub(bullEquity);
    }
    uint256 bullTokens = bullEquity.mul(1 ether).div(ivault.getPrice(bull));
    uint256 bearTokens = bearEquity.mul(1 ether).div(ivault.getPrice(bear));
    bullTokens = bullTokens > ivault.getLiqTokens(bull) ?
      ivault.getLiqTokens(bull) : bullTokens;
    bearTokens = bearTokens > ivault.getLiqTokens(bear) ?
      ivault.getLiqTokens(bear) : bearTokens;
    uint256 feesPaid = ivault.getLiqFees();
    feesPaid = feesPaid.mul(shares);
    feesPaid = feesPaid.mul(1 ether);
    feesPaid = feesPaid.div(ivault.getTotalLiqShares()).div(1 ether);
    feesPaid = shares <= ivault.getTotalLiqShares() ? feesPaid : ivault.getLiqFees();

    return(
      bullEquity,
      bearEquity,
      bullTokens,
      bearTokens,
      feesPaid
    );
  }

  function setbalanceControlFactor(uint256 amount) public onlyOwner() {
    balanceControlFactor = amount;
  }


}

