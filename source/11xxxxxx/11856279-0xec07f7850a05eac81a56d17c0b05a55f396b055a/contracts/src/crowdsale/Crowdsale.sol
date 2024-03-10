/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../../interfaces/uniswap/IUniswapV2Factory.sol';
import '../../interfaces/uniswap/IUniswapV2Router02.sol';

import '../investment/interfaces/IStakeFarm.sol';
import '../token/interfaces/IERC20WolfMintable.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

/**
 * @title Crowdsale
 *
 * @dev Crowdsale is a base contract for managing a token crowdsale, allowing
 * investors to purchase tokens with ether. This contract implements such
 * functionality in its most fundamental form and can be extended to provide
 * additional functionality and/or custom behavior.
 *
 * The external interface represents the basic interface for purchasing tokens,
 * and conforms the base architecture for crowdsales. It is *not* intended to
 * be modified / overridden.
 *
 * The internal interface conforms the extensible and modifiable surface of
 * crowdsales. Override the methods to add functionality. Consider using 'super'
 * where appropriate to concatenate behavior.
 */
contract Crowdsale is Context, ReentrancyGuard, AddressBook {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20WolfMintable;

  // The token being sold
  IERC20WolfMintable public token;

  // Address where funds are collected
  address payable private _wallet;

  // How many token units a buyer gets per wei.
  //
  // The rate is the conversion between wei and the smallest and indivisible
  // token unit. So, if you are using a rate of 1 with a ERC20Detailed token
  // with 3 decimals called TOK 1 wei will give you 1 unit, or 0.001 TOK.
  //
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  uint256 public cap;
  uint256 public investMin;
  uint256 public walletCap;

  uint256 public openingTime;
  uint256 public closingTime;

  // Per wallet investment (in wei)
  mapping(address => uint256) private _walletInvest;

  /**
   * Event for token purchase logging
   *
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * Event for add liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param amountToken how many token were added
   * @param amountETH how many ETH were added
   * @param liquidity how many pool tokens were created
   */
  event LiquidityAdded(
    address indexed beneficiary,
    uint256 amountToken,
    uint256 amountETH,
    uint256 liquidity
  );

  /**
   * Event for stake liquidity logging
   *
   * @param beneficiary who got the tokens
   * @param liquidity how many pool tokens were created
   */
  event Staked(address indexed beneficiary, uint256 liquidity);

  // Uniswap Router for providing liquidity
  IUniswapV2Router02 public immutable uniV2Router;
  IERC20 public immutable uniV2Pair;

  IStakeFarm public immutable stakeFarm;

  // Rate of tokens to insert into the UNISwapv2 liquidity pool
  //
  // Because they will be devided, expanding by multiples of 10
  // is fine to express decimal values.
  //
  uint256 private tokenForLp;
  uint256 private ethForLp;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen(), 'not open');
    _;
  }

  /**
   * @dev Crowdsale constructor
   *
   * @param _addressRegistry IAdressRegistry to get wallet and uniV2Router02
   * @param _rate Number of token units a buyer gets per wei
   *
   * The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   *
   * @param _token Address of the token being sold
   * @param _cap Max amount of wei to be contributed
   * @param _investMin minimum investment in wei
   * @param _walletCap Max amount of wei to be contributed per wallet
   * @param _lpEth numerator of liquidity pair
   * @param _lpToken denominator of liquidity pair
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(
    IAddressRegistry _addressRegistry,
    uint256 _rate,
    IERC20WolfMintable _token,
    uint256 _cap,
    uint256 _investMin,
    uint256 _walletCap,
    uint256 _lpEth,
    uint256 _lpToken,
    uint256 _openingTime,
    uint256 _closingTime
  ) {
    require(_rate > 0, 'rate is 0');
    require(address(_token) != address(0), 'token is addr(0)');
    require(_cap > 0, 'cap is 0');
    require(_lpEth > 0, 'lpEth is 0');
    require(_lpToken > 0, 'lpToken is 0');

    // solhint-disable-next-line not-rely-on-time
    require(_openingTime >= block.timestamp, 'opening > now');
    require(_closingTime > _openingTime, 'open > close');

    // Reverts if address is invalid
    IUniswapV2Router02 _uniV2Router =
      IUniswapV2Router02(
        _addressRegistry.getRegistryEntry(UNISWAP_V2_ROUTER02)
      );
    uniV2Router = _uniV2Router;

    // Get our liquidity pair
    address _uniV2Pair =
      IUniswapV2Factory(_uniV2Router.factory()).getPair(
        address(_token),
        _uniV2Router.WETH()
      );
    require(_uniV2Pair != address(0), 'invalid pair');
    uniV2Pair = IERC20(_uniV2Pair);

    // Reverts if address is invalid
    address _marketingWallet =
      _addressRegistry.getRegistryEntry(MARKETING_WALLET);
    _wallet = payable(_marketingWallet);

    // Reverts if address is invalid
    address _stakeFarm =
      _addressRegistry.getRegistryEntry(WETH_WOWS_STAKE_FARM);
    stakeFarm = IStakeFarm(_stakeFarm);

    rate = _rate;
    token = _token;
    cap = _cap;
    investMin = _investMin;
    walletCap = _walletCap;
    ethForLp = _lpEth;
    tokenForLp = _lpToken;
    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Fallback function ***DO NOT OVERRIDE***
   *
   * Note that other contracts will transfer funds with a base gas stipend
   * of 2300, which is not enough to call buyTokens. Consider calling
   * buyTokens directly when purchasing tokens from a contract.
   */
  receive() external payable {
    // A payable receive() function follows the OpenZeppelin strategy, in which
    // it is designed to buy tokens.
    //
    // However, because we call out to uniV2Router from the crowdsale contract,
    // re-imbursement of ETH from UniswapV2Pair must not buy tokens.
    //
    // Instead it must be payed to this contract as a first step and will then
    // be transferred to the recipient in _addLiquidity().
    //
    if (_msgSender() != address(uniV2Router)) buyTokens(_msgSender());
  }

  /**
   * @dev Checks whether the cap has been reached
   *
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @return True if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp >= openingTime && block.timestamp <= closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   *
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp > closingTime;
  }

  /**
   * @dev Provide a collection of UI relevant values to reduce # of queries
   *
   * @return ethRaised Amount eth raised (wei)
   * @return timeOpen Time presale opens (unix timestamp seconds)
   * @return timeClose Time presale closes (unix timestamp seconds)
   * @return timeNow Current time (unix timestamp seconds)
   * @return userEthInvested Amount of ETH users have already spent (wei)
   * @return userTokenAmount Amount of token held by user (token::decimals)
   */
  function getStates(address beneficiary)
    public
    view
    returns (
      uint256 ethRaised,
      uint256 timeOpen,
      uint256 timeClose,
      uint256 timeNow,
      uint256 userEthInvested,
      uint256 userTokenAmount
    )
  {
    uint256 tokenAmount =
      beneficiary == address(0) ? 0 : token.balanceOf(beneficiary);
    uint256 ethInvest = _walletInvest[beneficiary];

    return (
      weiRaised,
      openingTime,
      closingTime,
      // solhint-disable-next-line not-rely-on-time
      block.timestamp,
      ethInvest,
      tokenAmount
    );
  }

  /**
   * @dev Low level token purchase ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokens(address beneficiary) public payable nonReentrant {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // Update state
    weiRaised = weiRaised.add(weiAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);

    _forwardFunds(weiAmount);
  }

  /**
   * @dev Low level token purchase and liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokensAddLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
  {
    uint256 weiAmount = msg.value;

    // The ETH amount we buy WOWS token for
    uint256 buyAmount =
      weiAmount.mul(tokenForLp).div(rate.mul(ethForLp).add(tokenForLp));

    // The ETH amount we invest for liquidity (ETH + WOLF)
    uint256 investAmount = weiAmount.sub(buyAmount);

    _preValidatePurchase(beneficiary, buyAmount);

    // Calculate token amount to be created
    uint256 tokens = _getTokenAmount(buyAmount);

    // Verify that the ratio is in 0.1% limit
    uint256 tokensReverse = investAmount.mul(tokenForLp).div(ethForLp);
    require(
      tokens < tokensReverse || tokens.sub(tokensReverse) < tokens.div(1000),
      'ratio wrong'
    );
    require(
      tokens > tokensReverse || tokensReverse.sub(tokens) < tokens.div(1000),
      'ratio wrong'
    );

    // Update state
    weiRaised = weiRaised.add(buyAmount);
    _walletInvest[beneficiary] = _walletInvest[beneficiary].add(buyAmount);

    _processLiquidity(beneficiary, investAmount, tokens);

    _forwardFunds(buyAmount);
  }

  /**
   * @dev Low level token liquidity staking ***DO NOT OVERRIDE***
   *
   * This function has a non-reentrancy guard, so it shouldn't be called by
   * another `nonReentrant` function.
   *
   * approve() must be called before to let us transfer msgsenders tokens.
   *
   * @param beneficiary Recipient of the token purchase
   */
  function addLiquidity(address payable beneficiary)
    public
    payable
    nonReentrant
    onlyWhileOpen
  {
    uint256 weiAmount = msg.value;
    require(beneficiary != address(0), 'beneficiary is the zero address');
    require(weiAmount != 0, 'weiAmount is 0');

    // Calculate number of tokens
    uint256 tokenAmount = weiAmount.mul(tokenForLp).div(ethForLp);
    require(token.balanceOf(_msgSender()) >= tokenAmount, 'insufficient token');

    // Get the tokens from msg.sender
    token.safeTransferFrom(_msgSender(), address(this), tokenAmount);

    // Step 1: add liquidity
    uint256 lpToken =
      _addLiquidity(address(this), beneficiary, weiAmount, tokenAmount);

    // Step 2: we now own the liquidity tokens, stake them
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Finalize presale / create liquidity pool
   */
  function finalizePresale() external {
    require(hasClosed(), 'not closed');

    uint256 ethBalance = address(this).balance;
    require(ethBalance > 0, 'no eth balance');

    // Calculate how many token we add into liquidity pool
    uint256 tokenToLp = (ethBalance.mul(tokenForLp)).div(ethForLp);

    // Calculate amount unsold token
    uint256 tokenUnsold = cap.sub(weiRaised).mul(rate);

    // Mint token we spend
    require(
      token.mint(address(this), tokenToLp.add(tokenUnsold)),
      'minting failed'
    );

    _addLiquidity(_wallet, _wallet, ethBalance, tokenToLp);

    // Transfer all tokens from this contract to _wallet
    uint256 tokenInContract = token.balanceOf(address(this));
    if (tokenInContract > 0) token.transfer(_wallet, tokenInContract);

    // Finally whitelist uniV2 LP pool on token contract
    token.enableUniV2Pair(true);
  }

  /**
   * @dev Added to support recovering LP Rewards from other systems to be distributed to holders
   */
  function recoverERC20(address tokenAddress, uint256 tokenAmount) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(hasClosed(), 'not closed');
    // Cannot recover the staking token or the rewards token
    require(tokenAddress != address(token), 'native tokens unrecoverable');

    IERC20(tokenAddress).safeTransfer(_wallet, tokenAmount);
  }

  /**
   * @dev Change the closing time which gives you the possibility
   * to either shorten or enlarge the presale period
   */
  function setClosingTime(uint256 newClosingTime) external {
    require(msg.sender == _wallet, 'restricted to wallet');
    require(newClosingTime > openingTime, 'close < open');

    closingTime = newClosingTime;
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert
   * state when conditions are not met
   *
   * Use `super` in contracts that inherit from Crowdsale to extend their validations.
   *
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *     super._preValidatePurchase(beneficiary, weiAmount);
   *     require(weiRaised().add(weiAmount) <= cap);
   *
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address beneficiary, uint256 weiAmount)
    internal
    view
    onlyWhileOpen
  {
    require(beneficiary != address(0), 'beneficiary zero address');
    require(weiAmount != 0, 'weiAmount is 0');
    require(weiRaised.add(weiAmount) <= cap, 'cap exceeded');
    require(weiAmount >= investMin, 'invest too small');
    require(
      _walletInvest[beneficiary].add(weiAmount) <= walletCap,
      'wallet-cap exceeded'
    );

    // Silence state mutability warning without generating bytecode - see
    // https://github.com/ethereum/solidity/issues/2691
    this;
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * Doesn't necessarily emit/send tokens.
   *
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount)
    internal
  {
    require(token.mint(address(this), _tokenAmount), 'minting failed');
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed
   *
   * This function adds liquidity and stakes the liquidity in our initial farm.
   *
   * @param beneficiary Address receiving the tokens
   * @param ethAmount Amount of ETH provided
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processLiquidity(
    address payable beneficiary,
    uint256 ethAmount,
    uint256 tokenAmount
  ) internal {
    require(token.mint(address(this), tokenAmount), 'minting failed');

    // Step 1: add liquidity
    uint256 lpToken =
      _addLiquidity(address(this), beneficiary, ethAmount, tokenAmount);

    // Step 2: we now own the liquidity tokens, stake them
    // Allow stakeFarm to own our tokens
    uniV2Pair.approve(address(stakeFarm), lpToken);
    stakeFarm.stake(lpToken);

    // Step 3: transfer the stake to the user
    stakeFarm.transfer(beneficiary, lpToken);

    emit Staked(beneficiary, lpToken);
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   *
   * @param weiAmount Value in wei to be converted into tokens
   *
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 weiAmount) internal {
    _wallet.transfer(weiAmount.div(2));
  }

  function _addLiquidity(
    address tokenOwner,
    address payable remainingReceiver,
    uint256 ethBalance,
    uint256 tokenBalance
  ) internal returns (uint256) {
    // Add Liquidity, receiver of pool tokens is _wallet
    token.approve(address(uniV2Router), tokenBalance);

    (uint256 amountToken, uint256 amountETH, uint256 liquidity) =
      uniV2Router.addLiquidityETH{ value: ethBalance }(
        address(token),
        tokenBalance,
        tokenBalance.mul(90).div(100),
        ethBalance.mul(90).div(100),
        tokenOwner,
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 86400
      );

    emit LiquidityAdded(tokenOwner, amountToken, amountETH, liquidity);

    // Send remaining ETH to the team wallet
    if (amountETH < ethBalance)
      remainingReceiver.transfer(ethBalance.sub(amountETH));

    // Send remaining WOWS token to team wallet
    if (amountToken < tokenBalance)
      token.transfer(remainingReceiver, tokenBalance.sub(amountToken));

    return liquidity;
  }
}

