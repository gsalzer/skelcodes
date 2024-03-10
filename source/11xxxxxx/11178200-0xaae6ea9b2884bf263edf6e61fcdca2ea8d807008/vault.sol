//////////////////////////////////////////////////
//SYNLEV VAULT CONTRACT V 1.0.0
//////////////////////////

pragma solidity >= 0.6.6;

import './ownable.sol';
import './SafeMath.sol';
import './IERC20.sol';
import './priceCalculatorInterface.sol';
import './vaultHelperInterface.sol';
import './priceAggregatorInterface.sol';

/*
 * @title SynLev vault contract.
 * @author Icarus
 */
contract vault is Owned {
  using SafeMath for uint256;

  constructor() public {
    priceAggregatorInterface(0x7196545d854D03D9c87B7588F6D9e1e42D876E95).registerVaultAggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    priceAggregator = priceAggregatorInterface(0x73f27200093b74B3d21ff4df63E14a9E3fB85cd8);
    priceCalculator = priceCalculatorInterface(0xf4c56485A09388DbdcB01056E76A7B5bf7f5F574);
    vaultHelper = vaultHelperInterface(0xE0d6b68403D32Dd659E452DB880393Df15fA00F2);
    synStakingProxy = 0x0070F3e1147c03a1Bb0caF80035B7c362D312119;
    buyFee = 4 * 10**6;
    sellFee = 4 * 10**6;
  }

  /////////////////////
  //EVENTS/////////////
  /////////////////////
  event PriceUpdate(
    uint256 bullPrice,
    uint256 bearPrice,
    uint256 bullLiqEquity,
    uint256 bearLiqEquity,
    uint256 bullEquity,
    uint256 bearEquity,
    uint256 roundId,
    bool updated
  );
  event TokenBuy(
    address account,
    address token,
    uint256 tokensMinted,
    uint256 ethin,
    uint256 fees,
    uint256 bonus
  );
  event TokenSell(
    address account,
    address token,
    uint256 tokensBurned,
    uint256 ethout,
    uint256 fees,
    uint256 penalty
  );
  event LiquidityAdd(
    address account,
    uint256 eth,
    uint256 shares,
    uint256 shareprice
  );
  event LiquidityRemove(
    address account,
    uint256 eth,
    uint256 shares,
    uint256 shareprice
  );

  modifier isActive() {
    require(active == true);
    if(active == true && !priceAggregator.roundIdCheck(address(this))) {
      updatePrice();
    }
    _;
  }

  modifier updateIfActive() {
    if(active == true && !priceAggregator.roundIdCheck(address(this))) {
      updatePrice();
    }
    _;
  }

  /////////////////////
  //GLOBAL VARIBLES
  /////////////////////

  bool private active;
  uint256 constant private multiplier = 3;
  address private bull;
  address private bear;
  uint256 private latestRoundId;
  mapping(address => uint256) private price;
  mapping(address => uint256) private equity;
  uint256 private buyFee;
  uint256 private sellFee;
  uint256 private totalLiqShares;
  uint256 private liqFees;
  uint256 private balanceEquity;
  mapping(address => uint256) private liqTokens;
  mapping(address => uint256) private liqEquity;
  mapping(address => uint256) private userShares;

  priceAggregatorInterface  public priceAggregator;
  priceCalculatorInterface public priceCalculator;
  vaultHelperInterface public vaultHelper;
  address payable public synStakingProxy;

  //Fallback function
  receive() external payable {}

  ////////////////////////////////////
  //LOW LEVEL BUY AND SELL FUNCTIONS//
  //        NO SAFETY CHECK         //
  //SHOULD ONLY BE CALLED BY OTHER  //
  //          CONTRACTS             //
  ////////////////////////////////////

  /*
   * @notice Buys bull or bear token and updates price before token buy.
   * @param token bull or bear token address
   * @param account Recipient of newly minted tokens
   * @dev Should only be called by a router contract. Checks the excess ETH in
   * contract by calling getDepositEquity(). Can't 0 ETH buy. Calculates
   * resulting tokens and fees. Sends fees and mints tokens.
   *
   */
  function tokenBuy(address token, address account)
  public
  virtual
  isActive()
  {
    uint256 ethin = getDepositEquity();
    require(ethin > 0);
    require(token == bull || token == bear);
    IERC20 itkn = IERC20(token);
    uint256 fees = ethin.mul(buyFee).div(10**9);
    uint256 buyeth = ethin.sub(fees);
    uint256 bonus = vaultHelper.getBonus(address(this), token, buyeth);
    uint256 tokensToMint = buyeth.add(bonus).mul(10**18).div(price[token]);
    equity[token] = equity[token].add(buyeth).add(bonus);
    if(bonus != 0) balanceEquity = balanceEquity.sub(bonus);
    payFees(fees);
    itkn.mint(account, tokensToMint);

    emit TokenBuy(account, token, tokensToMint, ethin, fees, bonus);
  }

  /*
   * @notice Sells bull or bear token and updates price before token sell.
   * @param token bull or bear token address
   * @param account Recipient of resulting eth from burned tokens
   * @dev Should only be called by a router contract that simultaneously sends
   * tokens using transferFrom() and calls this function. Looks at the current
   * balance of the contract of the selected token. Can't 0 token sell.
   * Calculates resulting ETH from burned tokens. Pays fees, burns tokens, and
   * sends ETH.
   */
  function tokenSell(address token, address payable account)
  public
  virtual
  isActive()
  {
    IERC20 itkn = IERC20(token);
    uint256 tokensToBurn = itkn.balanceOf(address(this));
    require(tokensToBurn > 0);
    require(token == bull || token == bear);
    uint256 selleth = tokensToBurn.mul(price[token]).div(10**18);
    uint256 penalty = vaultHelper.getPenalty(address(this), token, selleth);
    uint256 fees = sellFee.mul(selleth.sub(penalty)).div(10**9);
    uint256 ethout = selleth.sub(penalty).sub(fees);
    equity[token] = equity[token].sub(selleth);
    if(penalty != 0) balanceEquity = balanceEquity.add(penalty);
    payFees(fees);
    itkn.burn(tokensToBurn);
    account.transfer(ethout);

    emit TokenSell(account, token, tokensToBurn, ethout, fees, penalty);
  }

  /*
   * @notice Adds liquidty to the contract and gives LP shares. Minimum LP add
   * is 1 wei. Virtually mints bear/bull tokens to be held in the vault.
   * @param account Recipient of LP shares
   * @dev Can be called by router but there is benefit to doing so. All
   * calculations are done with respect to equity and supply. Doing by price
   * creates rounding error. Calls updatePrice() then calls getLiqAddTokens()
   * to determine how many bull/bear to create.
   */
  function addLiquidity(address account)
  public
  payable
  virtual
  updateIfActive()
  {
    uint256 ethin = getDepositEquity();
    (
      uint256 bullEquity,
      uint256 bearEquity,
      uint256 bullTokens,
      uint256 bearTokens
    ) = vaultHelper.getLiqAddTokens(address(this), ethin);
    uint256 sharePrice = vaultHelper.getSharePrice(address(this));
    uint256 resultingShares = ethin.mul(10**18).div(sharePrice);
    liqEquity[bull] = liqEquity[bull].add(bullEquity);
    liqEquity[bear] = liqEquity[bear].add(bearEquity);
    liqTokens[bull] = liqTokens[bull].add(bullTokens);
    liqTokens[bear] = liqTokens[bear].add(bearTokens);
    userShares[account] = userShares[account].add(resultingShares);
    totalLiqShares = totalLiqShares.add(resultingShares);

    emit LiquidityAdd(account, ethin, resultingShares, sharePrice);
  }

  /*
   * @notice Removes liquidty to the contract and gives LP shares. Virtually
   * burns bear/bull tokens to be held in the vault. Cannot be called if user
   * has 0 shares
   * @param _shares How many shares to burn
   * @dev Cannot be called by a router as LP shares are not currently tokenized.
   * Calls updatePrice() then calls getLiqRemoveTokens() to determine how many
   * bull/bear tokens to remove.
   */
  function removeLiquidity(uint256 shares)
  public
  virtual
  updateIfActive()
  {
    require(shares <= userShares[msg.sender]);
    (
      uint256 bullEquity,
      uint256 bearEquity,
      uint256 bullTokens,
      uint256 bearTokens,
      uint256 feesPaid
    ) = vaultHelper.getLiqRemoveTokens(address(this), shares);
    uint256 sharePrice = vaultHelper.getSharePrice(address(this));
    uint256 resultingEth = bullEquity.add(bearEquity).add(feesPaid);
    liqEquity[bull] = liqEquity[bull].sub(bullEquity);
    liqEquity[bear] = liqEquity[bear].sub(bearEquity);
    liqTokens[bull] = liqTokens[bull].sub(bullTokens);
    liqTokens[bear] = liqTokens[bear].sub(bearTokens);
    userShares[msg.sender] = userShares[msg.sender].sub(shares);
    totalLiqShares = totalLiqShares.sub(shares);
    liqFees = liqFees.sub(feesPaid);
    msg.sender.transfer(resultingEth);

    emit LiquidityRemove(msg.sender, resultingEth, shares, sharePrice);
  }

  /*
   * @notice Updates price from chainlink oracles.
   * @param _shares How many shares to burn
   * @dev Calls getUpdatedPrice() function and sets new price, equity, liquidity
   * equity, and latestRoundId; only if there is new price data
   * @return bool if price was updated
   */
  function updatePrice()
  public
  {
    require(active == true);
    (
      uint256[6] memory priceArray,
      uint256 roundId,
      bool updated
    ) = priceCalculator.getUpdatedPrice(address(this), latestRoundId);
    if(updated == true) {
      (
        price[bull],
        price[bear],
        liqEquity[bull],
        liqEquity[bear],
        equity[bull],
        equity[bear],
        latestRoundId
      ) =
      (
        priceArray[0],
        priceArray[1],
        priceArray[2],
        priceArray[3],
        priceArray[4],
        priceArray[5],
        roundId
      );
    }
    emit PriceUpdate(
      price[bull],
      price[bear],
      liqEquity[bull],
      liqEquity[bear],
      equity[bull],
      equity[bear],
      latestRoundId,
      updated
    );
  }

  ///////////////////////
  //INTERNAL FUNCTIONS///
  ///////////////////////

  /*
   * @notice Pays half fees to SYN stakers and half to LP
   * @param _amount Fees to be paid in ETH
   * @dev Only called by tokenBuy() and tokenSell()
   */
  function payFees(uint256 amount) internal {
    synStakingProxy.transfer(amount.div(2));
    liqFees += amount.sub(amount.div(2));
  }

  ///////////////////
  ///VIEW FUNCTIONS//
  ///////////////////
  function getActive() public view returns(bool) {return(active);}
  function getMultiplier() public pure returns(uint256) {return(multiplier);}
  function getBullToken() public view returns(address) {return(bull);}
  function getBearToken() public view returns(address) {return(bear);}
  function getLatestRoundId() public view returns(uint256) {return(latestRoundId);}
  function getPrice(address token) public view returns(uint256) {return(price[token]);}
  function getEquity(address token) public view returns(uint256) {return(equity[token]);}
  function getBuyFee() public view returns(uint256) {return(buyFee);}
  function getSellFee() public view returns(uint256) {return(sellFee);}
  function getTotalLiqShares() public view returns(uint256) {return(totalLiqShares);}
  function getLiqFees() public view returns(uint256) {return(liqFees);}
  function getBalanceEquity() public view returns(uint256) {return(balanceEquity);}
  function getLiqTokens(address token) public view returns(uint256) {return(liqTokens[token]);}
  function getLiqEquity(address token) public view returns(uint256) {return(liqEquity[token]);}
  function getUserShares(address account) public view returns(uint256) {return(userShares[account]);}

  function getTotalEquity() public view returns(uint256) {
    return(getTokenEquity(bear).add(getTokenEquity(bull)));
  }

  function getTokenEquity(address token) public view returns(uint256) {
    return(equity[token].add(liqEquity[token]));
  }
  function getTokenLiqEquity(address token) public view returns(uint256) {
    return(liqTokens[token].mul(price[token]).div(10**18));
  }
  function getDepositEquity() public view returns(uint256) {
    return(address(this).balance.sub(liqFees.add(balanceEquity).add(getTotalEquity())));
  }
  ///////////////////
  //ADMIN FUNCTIONS//
  ///////////////////

  //One time use function to set token addresses. this can never be changed once set.
  //Cannot be included in constructor as vault must be deployed before tokens.
  function setTokens(address bearAddress, address bullAddress) public onlyOwner() {
    require(bear == address(0) || bull == address(0));
    (bull, bear) = (bullAddress, bearAddress);
    //Set initial price to .01 eth
    (price[bull], price[bear]) = (10**16, 10**16);
  }
  function setActive(bool state, uint256 roundId) public onlyOwner() {
    active = state;
    if(roundId == 0) {
      ( , latestRoundId) = priceAggregator.priceRequest(address(this), latestRoundId);
    }
    else {
      latestRoundId == roundId;
    }
  }
  //Fees in the form of 1 / 10^8
  function setBuyFee(uint256 amount) public onlyOwner() {
    require(amount <= 10**9);
    buyFee = amount;
  }
  //Sell fees limited to a maximum of 1%
  function setSellFee(uint256 amount) public onlyOwner() {
    require(amount <= 10**7);
    sellFee = amount;
  }

}

