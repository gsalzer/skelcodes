// SPDX-License-Identifier: <SPDX-License>

pragma solidity 0.6.12;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "./token/ERC20/ERC20.sol";
import "./lib/SafeMathInt.sol";



/**
 * @title Bitbase ERC20 token
 * @dev This is part of an implementation of the Bitbase Index Fund protocol.
 *      Bitbase is an ERC20 token with a 1% cloud yield protocol on every single transfer.
 *
 *      Bitbase balances are internally represented with a hidden denomination, 'shares'.
 *      We support splitting the currency in expansion and combining the currency on contraction by
 *      changing the exchange rate between the hidden 'shares' and the public 'Bitbase' token.
 */

contract BitbaseToken is ERC20UpgradeSafe, OwnableUpgradeSafe {
  using SafeMath for uint256;
  using SafeMathInt for int256;

  event LogReBitbase(uint256 indexed epoch, uint256 totalSupply);
  event LogMonetaryPolicyUpdated(address monetaryPolicy);
  event LogUserBanStatusUpdated(address user, bool banned);
  event cloudYield(uint256 amount, uint256 time);

  // Used for authentication
  address public monetaryPolicy;

  modifier validRecipient(address to) {
    require(to != address(0x0));
    require(to != address(this));
    _;
  }

  uint256 private constant DECIMALS = 9;
  uint256 private constant MAX_UINT256 = ~uint256(0);
  uint256 private constant INITIAL_SUPPLY = 200_000 * 10**DECIMALS;
  uint256 private constant INITIAL_SHARES = (MAX_UINT256 / (10**32)) - ((MAX_UINT256 / (10**32)) % INITIAL_SUPPLY);
  uint256 private constant MAX_SUPPLY = ~uint128(0); // (2^128) - 1

  uint256 private _totalShares;
  uint256 private _totalSupply;
  uint256 private _sharesPerBitbase;
  mapping(address => uint256) private _shareBalances;

  mapping(address => bool) public bannedUsers;

  // This is denominated in BitbaseToken, because the sharesperBitbase conversion might change before
  // it's fully paid.
  mapping(address => mapping(address => uint256)) private _allowedBitbase;

  bool public transfersPaused;
  bool public reBitbasesPaused;

  mapping(address => bool) public transferPauseExemptList;

  function setTransfersPaused(bool _transfersPaused) public onlyOwner {
    transfersPaused = _transfersPaused;
  }

  function setTransferPauseExempt(address user, bool exempt) public onlyOwner {
    if (exempt) {
      transferPauseExemptList[user] = true;
    } else {
      delete transferPauseExemptList[user];
    }
  }

  function setReBitbasesPaused(bool _reBitbasesPaused) public onlyOwner {
    reBitbasesPaused = _reBitbasesPaused;
  }

  /**
   * @param monetaryPolicy_ The address of the monetary policy contract to use for authentication.
   */
  function setMonetaryPolicy(address monetaryPolicy_) external onlyOwner {
    monetaryPolicy = monetaryPolicy_;
    emit LogMonetaryPolicyUpdated(monetaryPolicy_);
  }

  /**
   * @dev Notifies BitbaseToken contract about a new rebase cycle.
   * @param supplyDelta The number of new Bitbase tokens to add into circulation via expansion.
   * @return The total number of Bitbase after the supply adjustment.
   * Only callable from the monetary policy contract
   */
  function rebase(uint256 epoch, int256 supplyDelta) external returns (uint256) {
    require(msg.sender == monetaryPolicy, "only monetary policy");
    require(!reBitbasesPaused, "rebases paused");

    if (supplyDelta == 0) {
      emit LogReBitbase(epoch, _totalSupply);
      return (_totalSupply);
    }

    if (supplyDelta < 0) {
      _totalSupply = _totalSupply.sub(uint256(supplyDelta.abs()));
    } else {
      _totalSupply = _totalSupply.add(uint256(supplyDelta));
    }

    if (_totalSupply > MAX_SUPPLY) {
      _totalSupply = MAX_SUPPLY;
    }

    _sharesPerBitbase = _totalShares.div(_totalSupply);

    // From this point forward, _sharesPerBitbase is taken as the source of truth.
    // We recalculate a new _totalSupply to be in agreement with the _sharesPerBitbase
    // conversion rate.
    // This means our applied supplyDelta can deviate from the requested supplyDelta,
    // but this deviation is guaranteed to be < (_totalSupply^2)/(totalShares - _totalSupply).
    //
    // In the case of _totalSupply <= MAX_UINT128 (our current supply cap), this
    // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
    // ever increased, it must be re-included.

    emit LogReBitbase(epoch, _totalSupply);
    return (_totalSupply);
  }

  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  function sharesOf(address user) public view returns (uint256) {
    return _shareBalances[user];
  }

  function initialize() public initializer {
    __ERC20_init("Bitbase", "BITB");
    __Ownable_init();
    _setupDecimals(uint8(DECIMALS));

    _totalShares = INITIAL_SHARES;
    _totalSupply = INITIAL_SUPPLY;

    uint256 BBDevDist = _totalShares.mul(4000).div(1e5);
    _shareBalances[0x404ad1A8bb4467e16c1098354a2cfb679eC82c92] = BBDevDist;
    emit Transfer(address(0), 0x404ad1A8bb4467e16c1098354a2cfb679eC82c92, 8000 * 1e9);

    _sharesPerBitbase = _totalShares.div(_totalSupply);
    // Ban the Kucoin hacker
    bannedUsers[0xeB31973E0FeBF3e3D7058234a5eBbAe1aB4B8c23] = true;
  }

  function setUserBanStatus(address user, bool banned) public onlyOwner {
    if (banned) {
      bannedUsers[user] = true;
    } else {
      delete bannedUsers[user];
    }
    emit LogUserBanStatusUpdated(user, banned);
  }

  /**
   * @return The total number of Bitbase.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  /**
   * @param who The address to query.
   * @return The balance of the specified address.
   */
  function balanceOf(address who) public view override returns (uint256) {
    uint256 shareAmount = _shareBalances[who];

    return shareAmount.div(_sharesPerBitbase);
  }

  /**
   * @dev Transfer tokens to a specified address.
   * @param to The address to transfer to.
   * @param value The amount to be transferred.
   * @return True on success, false otherwise.
   */
  function transfer(address to, uint256 value) public override(ERC20UpgradeSafe) validRecipient(to) returns (bool) {
    require(bannedUsers[msg.sender] == false, "you are banned");
    require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
    require(value > 100000, "Sending too little");

    uint256 sharesToTransfer = _beforeTokenTransfer(msg.sender, to, value);

    // Transfer to recepient
    _shareBalances[msg.sender] = _shareBalances[msg.sender].sub(sharesToTransfer);
    _shareBalances[to] = _shareBalances[to].add(sharesToTransfer);

    /** @dev DEFLECT NOTE: Exclude LGE from both, the burn and yield.
     *  _cloudYield 1% of the transaction
     */
    if (!excluded[msg.sender]) {
      uint256 burnAmount = value.mul(1000).div(1e5); //1%
      _cloudYield(msg.sender, burnAmount);
    }
    emit Transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner has allowed to a spender.
   * @param owner_ The address which owns the funds.
   * @param spender The address which will spend the funds.
   * @return The number of tokens still available for the spender.
   */
  function allowance(address owner_, address spender) public view override returns (uint256) {
    return _allowedBitbase[owner_][spender];
  }

  /**
   * @dev Transfer tokens from one address to another.
   * @param from The address you want to send tokens from.
   * @param to The address you want to transfer to.
   * @param value The amount of tokens to be transferred.
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  ) public override validRecipient(to) returns (bool) {
    require(bannedUsers[msg.sender] == false, "you are banned");
    require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");
    require(value > 100000, "Sending too little");

    uint256 sharesToTransfer = _beforeTokenTransfer(from, to, value);

    _allowedBitbase[from][msg.sender] = _allowedBitbase[from][msg.sender].sub(value);

    // Transfer to recepient
    _shareBalances[from] = _shareBalances[from].sub(sharesToTransfer);
    _shareBalances[to] = _shareBalances[to].add(sharesToTransfer);

    /** @dev DEFLECT NOTE: Exclude LGE from both, the burn and yield.
     *  _cloudYield 1% of the transaction
     */
    if (!excluded[from]) {
      uint256 burnAmount = value.mul(1000).div(1e5);
      _cloudYield(from, burnAmount);
    }

    emit Transfer(from, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of
   * msg.sender. This method is included for ERC20 compatibility.
   * increaseAllowance and decreaseAllowance should be used instead.
   * Changing an allowance with this method brings the risk that someone may transfer both
   * the old and the new allowance - if they are both greater than zero - if a transfer
   * transaction is mined before the later approve() call is mined.
   *
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public override returns (bool) {
    require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

    _allowedBitbase[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner has allowed to a spender.
   * This method should be used instead of approve() to avoid the double approval vulnerability
   * described above.
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
    require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

    _allowedBitbase[msg.sender][spender] = _allowedBitbase[msg.sender][spender].add(addedValue);
    emit Approval(msg.sender, spender, _allowedBitbase[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner has allowed to a spender.
   *
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
    require(!transfersPaused || transferPauseExemptList[msg.sender], "paused");

    uint256 oldValue = _allowedBitbase[msg.sender][spender];
    if (subtractedValue >= oldValue) {
      _allowedBitbase[msg.sender][spender] = 0;
    } else {
      _allowedBitbase[msg.sender][spender] = oldValue.sub(subtractedValue);
    }
    emit Approval(msg.sender, spender, _allowedBitbase[msg.sender][spender]);
    return true;
  }

  function _cloudYield(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _shareBalances[account].div(_sharesPerBitbase));

    //convert this amount to shares
    uint256 shareAmount = amount.mul(_sharesPerBitbase);

    //subtract this amount of fragments from their balance
    _shareBalances[account] = _shareBalances[account].sub(shareAmount);

    //update total shares
    _totalShares = _totalShares.sub(shareAmount);

    //update shares per token
    _sharesPerBitbase = _totalShares.div(_totalSupply);

    //emit Burn and yield
    emit Transfer(account, address(0), amount);
    emit cloudYield(amount, now);
  }

  /** DEFLECT LGE ADDITIONS */

  // LGE status
  bool public lgeInitialized;

  // The base ETH/BITB uniswap pair.
  IERC20 public bitbaseETHLPToken;

  // The last amount of LP tokens in the pair
  uint256 lastTotalSupplyOfLPTokens;

  // Exclude these accounts from yield / burn.
  mapping(address => bool) public excluded;

  function initializeLGE(
    address _lgeAddr,
    address _bitbaseETHLPToken,
    address _deflectTreasuryAddr,
    address _bitbaseTreasuryAddr
  ) external onlyOwner {
    require(!lgeInitialized, "LGE already initialized");
    bitbaseETHLPToken = IERC20(_bitbaseETHLPToken);

    // Do not have token properties applied for the LGE address.
    toggleExcluded(_lgeAddr);
    // Distribute the funds here according the following specs.
    // 120,000 to the LGE
    // 45,000 to DFLECT (5k treasury, 40k for staking pools)
    // 27,000 to BitBase treasury.
    // Remaining 8k (4%) is already distributed to the bitbase developer.
    uint256 lgeDist = _totalShares.mul(60000).div(1e5);
    _shareBalances[_lgeAddr] = lgeDist;
    emit Transfer(address(0), _lgeAddr, 120000 * 1e9);

    uint256 dflectTreasuryDist = _totalShares.mul(22500).div(1e5);
    _shareBalances[_deflectTreasuryAddr] = dflectTreasuryDist;
    emit Transfer(address(0), _deflectTreasuryAddr, 45000 * 1e9);

    uint256 bitbaseTreasuryDist = _totalShares.mul(13500).div(1e5);
    _shareBalances[_bitbaseTreasuryAddr] = bitbaseTreasuryDist;
    emit Transfer(address(0), _bitbaseTreasuryAddr, 27000 * 1e9);
    lgeInitialized = true;
  }

  // Toggle the excluded status of an address.
  function toggleExcluded(address _target) public onlyOwner {
    excluded[_target] = !excluded[_target];
  }

  // Transfer checker hook used to check wheter we are in fact dealing with an LP removal.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override returns (uint256) {
    // Get the current LP token amount
    uint256 _LPSupplyOfPairTotal = bitbaseETHLPToken.totalSupply();

    // Check that current supply is bigger or equal to the last supply.
    // This means liquidity additions and transfers can be made, but not removals.
    if (from == address(bitbaseETHLPToken)) {
      require(lastTotalSupplyOfLPTokens <= _LPSupplyOfPairTotal, "Liquidity withdrawals forbidden");
    }
    // Sync the book-keeping variable to be up-to-date for the next transfer.
    lastTotalSupplyOfLPTokens = _LPSupplyOfPairTotal;
    uint256 rate = 99000; //99%
    if (excluded[from]) rate = 100000;

    return (amount.mul(rate).div(1e5)).mul(_sharesPerBitbase);
  }
}

