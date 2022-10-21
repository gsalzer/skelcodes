pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
// DAI and ETH have different implements of this methods but we require implement this method
contract SmartFundOverrideInterface {
  function calculateFundValue() public view returns (uint256);
  function getTokenValue(ERC20 _token) public view returns (uint256);
}
contract PermittedPoolsInterface {
  mapping (address => bool) public permittedAddresses;
}
contract PermittedExchangesInterface {
  mapping (address => bool) public permittedAddresses;
}


contract PoolPortalInterface {
  function buyPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
  external
  payable;

  function sellPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
  external
  payable;

  function getBacorConverterAddressByRelay(address relay)
  public
  view
  returns(address converter);

  function getBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    ERC20 _relay
  )
  public view returns(uint256 bancorAmount, uint256 connectorAmount);

  function getBancorConnectorsByRelay(address relay)
  public
  view
  returns(
    ERC20 BNTConnector,
    ERC20 ERCConnector
  );

  function getBancorRatio(address _from, address _to, uint256 _amount)
  public
  view
  returns(uint256);

  function getUniswapConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  public
  view
  returns(uint256 ethAmount, uint256 ercAmount);

  function getUniswapTokenAmountByETH(address _token, uint256 _amount)
  public
  view
  returns(uint256);

  function getTokenByUniswapExchange(address _exchange)
  public
  view
  returns(address);
}


contract ExchangePortalInterface {

  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);

  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs,
    bytes _additionalData
  )
    external
    payable
    returns (uint256);

  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256);
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256);
}


contract CToken {
    address public underlying;
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint(uint mintAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CToken cTokenCollateral) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function exchangeRateCurrent() external view returns (uint);
    function totalSupply() external view returns(uint);
    function balanceOfUnderlying(address account) external view returns (uint);
}


contract SmartFundInterface {
  // the total number of shares in the fund
  uint256 totalShares;

  // how many shares belong to each address
  mapping (address => uint256) public addressToShares;
  // sends percentage of fund tokens to the user
  // function withdraw() external;
  function withdraw(uint256 _percentageWithdraw) external;

  // for smart fund owner to trade tokens
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] additionalArgs,
    bytes _additionalData
  )
    external;

  function buyPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
    external;

  function sellPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
    external;

  // calculates the number of shares a buyer will receive for depositing `amount` of ether
  function calculateDepositToShares(uint256 _amount) public view returns (uint256);
}



contract CEther{
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function liquidateBorrow(address borrower, CToken cTokenCollateral) external payable;
    function exchangeRateCurrent() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOfUnderlying(address account) external view returns (uint);
}
// due eip-170 error we should create 2 factory one for ETH another for USD






/*
* This contract inherits logic of SmartFundCore and implements logic of Compound.
* Perhaps in the future we will need select for inherit the logic of Lend or not,
* therefore, this logic must be separate
*
* NOTE: maybe in future, if we don't need implement borrow logic, and no need bind
* debt with msg.sender, we can do Compound logic as addition portal
*/





/*
  The SmartFund contract is what holds all the tokens and ether, and contains all the logic
  for calculating its value (and ergo profit), allows users to deposit/withdraw their funds,
  and calculates the fund managers cut of the funds profit among other things.
  The SmartFund gets the value of its token holdings (in Ether) and trades through the ExchangePortal
  contract. This means that as new exchange capabalities are added to new exchange portals, the
  SmartFund will be able to upgrade to a new exchange portal, and trade a wider variety of assets
  with a wider variety of exchanges. The SmartFund is also connected to a PermittedExchanges contract,
  which determines which exchange portals the SmartFund is allowed to connect to, restricting
  the fund owners ability to connect to a potentially malicious contract.
*/












/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



contract SmartFundCore is SmartFundOverrideInterface, Ownable, ERC20 {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // Total amount of ether or stable deposited by all users
  uint256 public totalWeiDeposited = 0;

  // Total amount of ether or stable withdrawn by all users
  uint256 public totalWeiWithdrawn = 0;

  // The Interface of the Exchange Portal
  ExchangePortalInterface public exchangePortal;

  // The Interface of pool portall
  PoolPortalInterface public poolPortal;

  // The Smart Contract which stores the addresses of all the authorized Exchange Portals
  PermittedExchangesInterface public permittedExchanges;

  // The Smart Contract which stores the addresses of all the authorized Pools Portals
  PermittedPoolsInterface public permittedPools;

  // KyberExchange recognizes ETH by this address
  ERC20 constant internal ETH_TOKEN_ADDRESS = ERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

  // For ERC20 compliance
  string public name;

  // The maximum amount of tokens that can be traded via the smart fund
  uint256 public MAX_TOKENS = 50;

  // Percentages are rounded to 3 decimal places
  uint256 public TOTAL_PERCENTAGE = 10000;

  // Address of the platform that takes a cut from the fund manager success cut
  address public platformAddress;

  // The percentage of earnings paid to the fund manager. 10000 = 100%
  // e.g. 10% is 1000
  uint256 public successFee;

  // The percentage of fund manager earnings paid to the platform. 10000 = 100%
  // e.g. 10% is 1000
  uint256 public platformFee;

  // An array of all the erc20 token addresses the smart fund holds
  address[] public tokenAddresses;

  // mapping for check certain token is relay or not
  mapping(address => bool) public isRelay;

  // Boolean value that determines whether the fund accepts deposits from anyone or
  // only specific addresses approved by the manager
  bool public onlyWhitelist = false;

  // Mapping of addresses that are approved to deposit if the manager only want's specific
  // addresses to be able to invest in their fund
  mapping (address => bool) public whitelist;

  uint public version = 5;

  // the total number of shares in the fund
  uint256 public totalShares = 0;

  // Denomination of initial shares
  uint256 constant internal INITIAL_SHARES = 10 ** 18;

  // The earnings the fund manager has already cashed out
  uint256 public fundManagerCashedOut = 0;

  // how many shares belong to each address
  mapping (address => uint256) public addressToShares;

  // so that we can easily check that we don't add duplicates to our array
  mapping (address => bool) public tokensTraded;

  // this is really only being used to more easily show profits, but may not be necessary
  // if we do a lot of this offchain using events to track everything
  // total `depositToken` deposited - total `depositToken` withdrawn
  mapping (address => int256) public addressesNetDeposit;

  // Events
  event BuyPool(address poolToken, uint256 amount);
  event SellPool(address poolToken, uint256 amount);
  event Deposit(address indexed user, uint256 amount, uint256 sharesReceived, uint256 totalShares);
  event Withdraw(address indexed user, uint256 sharesRemoved, uint256 totalShares);
  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);
  event SmartFundCreated(address indexed owner);

  // enum
  enum PortalType { Bancor, Uniswap }

  constructor(
    address _owner,
    string _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platformAddress,
    address _exchangePortalAddress,
    address _permittedExchangesAddress,
    address _permittedPoolsAddress,
    address _poolPortalAddress
  )public{
    // never allow a 100% fee
    require(_successFee < TOTAL_PERCENTAGE);
    require(_platformFee < TOTAL_PERCENTAGE);

    name = _name;
    successFee = _successFee;
    platformFee = _platformFee;

    if(_owner == address(0)){
      owner = msg.sender;
    }
    else{
      owner = _owner;
    }

    if(_platformAddress == address(0)){
      platformAddress = msg.sender;
    }
    else{
      platformAddress = _platformAddress;
    }

    // Initial Token is Ether
    tokenAddresses.push(address(ETH_TOKEN_ADDRESS));

    // Initial interfaces
    exchangePortal = ExchangePortalInterface(_exchangePortalAddress);
    permittedExchanges = PermittedExchangesInterface(_permittedExchangesAddress);
    permittedPools = PermittedPoolsInterface(_permittedPoolsAddress);
    poolPortal = PoolPortalInterface(_poolPortalAddress);

    emit SmartFundCreated(owner);
  }

  /**
  * @dev Sends (_mul/_div) of every token (and ether) the funds holds to _withdrawAddress
  *
  * @param _mul                The numerator
  * @param _div                The denominator
  * @param _withdrawAddress    Address to send the tokens/ether to
  *
  * NOTE: _withdrawAddress changed from address to address[] arrays because balance calculation should be performed
  * once for all usesr who wants to withdraw from the current balance.
  *
  */
  function _withdraw(uint256[] _mul, uint256[] _div, address[] memory _withdrawAddress) internal returns (uint256) {
    for (uint8 i = 1; i < tokenAddresses.length; i++) {
      // Transfer that _mul/_div of each token we hold to the user
      ERC20 token = ERC20(tokenAddresses[i]);
      uint256 fundAmount = token.balanceOf(address(this));

      // Transfer ERC20 to _withdrawAddress
      for(uint8 j = 0; j < _withdrawAddress.length; j++){
        uint256 payoutAmount = fundAmount.mul(_mul[j]).div(_div[j]);
        token.transfer(_withdrawAddress[j], payoutAmount);
      }
    }
     uint256 etherBalance = address(this).balance;
     // Transfer ETH to _withdrawAddress
     for(uint8 k = 0; k < _withdrawAddress.length; k++){
       uint256 etherPayoutAmount = (etherBalance).mul(_mul[k]).div(_div[k]);
       _withdrawAddress[k].transfer(etherPayoutAmount);
     }
  }

  /**
  * @dev Withdraws users fund holdings, sends (userShares/totalShares) of every held token
  * to msg.sender, defaults to 100% of users shares.
  *
  * @param _percentageWithdraw    The percentage of the users shares to withdraw.
  */
  function withdraw(uint256 _percentageWithdraw) external {
    require(totalShares != 0);

    uint256 percentageWithdraw = (_percentageWithdraw == 0) ? TOTAL_PERCENTAGE : _percentageWithdraw;

    uint256 addressShares = addressToShares[msg.sender];

    uint256 numberOfWithdrawShares = addressShares.mul(percentageWithdraw).div(TOTAL_PERCENTAGE);

    uint256 fundManagerCut;
    uint256 fundValue;

    // Withdraw the users share minus the fund manager's success fee
    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 withdrawShares = numberOfWithdrawShares.mul(fundValue.sub(fundManagerCut)).div(fundValue);

    // prepare call data for _withdarw
    address[] memory spenders = new address[](1);
    spenders[0] = msg.sender;

    uint256[] memory value = new uint256[](1);
    value[0] = totalShares;

    uint256[] memory cut = new uint256[](1);
    cut[0] = withdrawShares;

    // do withdraw
    _withdraw(cut, value, spenders);

    // Store the value we are withdrawing in ether
    uint256 valueWithdrawn = fundValue.mul(withdrawShares).div(totalShares);

    totalWeiWithdrawn = totalWeiWithdrawn.add(valueWithdrawn);
    addressesNetDeposit[msg.sender] -= int256(valueWithdrawn);

    // Subtract from total shares the number of withdrawn shares
    totalShares = totalShares.sub(numberOfWithdrawShares);
    addressToShares[msg.sender] = addressToShares[msg.sender].sub(numberOfWithdrawShares);

    emit Withdraw(msg.sender, numberOfWithdrawShares, totalShares);
  }

  /**
  * @dev Facilitates a trade of the funds holdings via the exchange portal
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with
  * @param _additionalArgs    Array of bytes32 additional arguments
  * @param _additionalData    For any size data (if not used set just 0x0)
  */
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs,
    bytes _additionalData
  ) external onlyOwner {

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      // Make sure fund contains enough ether
      require(address(this).balance >= _sourceAmount);
      // Call trade on ExchangePortal along with ether
      receivedAmount = exchangePortal.trade.value(_sourceAmount)(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _additionalArgs,
        _additionalData
      );
    } else {
      _source.approve(exchangePortal, _sourceAmount);
      receivedAmount = exchangePortal.trade(
        _source,
        _sourceAmount,
        _destination,
        _type,
        _additionalArgs,
        _additionalData
      );
    }

    if (receivedAmount > 0)
      _addToken(_destination);

    emit Trade(_source, _sourceAmount, _destination, receivedAmount);
  }


  /**
  * @dev buy pool via pool portal
  *
  * @param _amount        For Bancor amount it's relay, for Uniswap amount it's ETH
  * @param _type          type of pool (0 - Bancor, 1 - Uniswap)
  * @param _poolToken     address of relay for Bancor and exchange for Uniswap
  */
  function buyPool(
   uint256 _amount,
   uint _type,
   ERC20 _poolToken
  )
  external onlyOwner {
   // buy Bancor or Uniswap pool
   if(_type == uint(PortalType.Bancor))
    _buyBancorPool(_amount, _type, _poolToken);
   if(_type == uint(PortalType.Uniswap))
    _buyUniswapPool(_amount, _type, _poolToken);

   // add new pool in fund
   uint256 poolBalance = _poolToken.balanceOf(address(this));
   if(poolBalance > 0){
     // Add relay as ERC20 for withdraw assets
     _addToken(address(_poolToken));
     // Mark this token as relay
     _markAsRelay(address(_poolToken));
   }

   // emit event
   emit BuyPool(_poolToken, _amount);
  }

  // Helper for buy Uniswap pool
  function _buyUniswapPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
  private
  {
    // approve connector
    ERC20 token = ERC20(poolPortal.getTokenByUniswapExchange(_poolToken));
    token.approve(address(poolPortal), token.balanceOf(address(this)));

    // buy pool via ETH amount payable
    poolPortal.buyPool.value(_amount)(
     _amount,
     _type,
    _poolToken
    );

    //reset approve
    token.approve(address(poolPortal), 0);
  }

  // Helper for buy Bancor pool
  function _buyBancorPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  ) private
  {
    // get connectors
    (ERC20 bancorConnector,
       ERC20 ercConnector) = poolPortal.getBancorConnectorsByRelay(address(_poolToken));

    // Approve all connectors to pool portal (pool calculates the required amount dynamicly)
    bancorConnector.approve(address(poolPortal), bancorConnector.balanceOf(address(this)));
    ercConnector.approve(address(poolPortal), ercConnector.balanceOf(address(this)));

    // buy pool(relay) via relay amount not payable
    poolPortal.buyPool(
     _amount,
     _type,
    _poolToken
    );

    // reset approve
    bancorConnector.approve(address(poolPortal), 0);
    ercConnector.approve(address(poolPortal), 0);
  }


  /**
  * @dev sell pool via pool portal
  *
  * @param _amount        amount of Bancor relay or Uniswap exchange to sell
  * @param _type          type of pool (0 - Bancor, 1 - Uniswap)
  * @param _poolToken     address of Bancor relay or Uniswap exchange
  */
  function sellPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken
  )
  external onlyOwner {
    // approve
    _poolToken.approve(address(poolPortal), _amount);

    // sell
    poolPortal.sellPool(
      _amount,
      _type,
     _poolToken
    );

    // add to fund pool connectors
    if(_type == uint(PortalType.Bancor))
     _addBancorResereve(_poolToken);

    if(_type == uint(PortalType.Uniswap))
     _addUniswapReserve(_poolToken);

    // event
    emit SellPool(_poolToken, _amount);
  }

  // Helper for exctract Bancor pool connectos and add this connectors to fund
  function _addBancorResereve(address _poolToken)
  private
  {
    // get bancor connectors addresses
    (ERC20 bancorConnector,
      ERC20 ercConnector) = poolPortal.getBancorConnectorsByRelay(
        address(_poolToken));

    // add returned assets in fund as tokens (for case if manager removed this assets)
    _addToken(address(bancorConnector));
    _addToken(address(ercConnector));
  }

  // Helper for exctract Uniswap pool connector and add this connector to fund
  function _addUniswapReserve(address _poolToken)
  private
  {
    // extract Uniswap connector
    address tokenAddress = poolPortal.getTokenByUniswapExchange(_poolToken);
    // add returned asset to fund(for case if manager removed this asset)
    _addToken(tokenAddress);
  }

  function getAllTokenAddresses() public view returns (address[]) {
    return tokenAddresses;
  }

  /**
  * @dev Adds a token to tokensTraded if it's not already there
  * @param _token    The token to add
  */
  function _addToken(address _token) internal {
    // don't add token to if we already have it in our list
    if (tokensTraded[_token] || (_token == address(ETH_TOKEN_ADDRESS)))
      return;

    tokensTraded[_token] = true;
    uint256 tokenCount = tokenAddresses.push(_token);

    // we can't hold more than MAX_TOKENS tokens
    require(tokenCount <= MAX_TOKENS);
  }

  /**
  * @dev Removes a token from tokensTraded
  *
  * @param _token         The address of the token to be removed
  * @param _tokenIndex    The index of the token to be removed
  *
  */
  function removeToken(address _token, uint256 _tokenIndex) public onlyOwner {
    require(_token != address(ETH_TOKEN_ADDRESS));
    require(tokensTraded[_token]);
    require(ERC20(_token).balanceOf(address(this)) == 0);
    require(tokenAddresses[_tokenIndex] == _token);

    tokensTraded[_token] = false;

    // remove token from array
    uint256 arrayLength = tokenAddresses.length - 1;
    tokenAddresses[_tokenIndex] = tokenAddresses[arrayLength];
    delete tokenAddresses[arrayLength];
    tokenAddresses.length--;
  }



  /**
  * @dev mark ERC20 as relay
  * @param _token   The token address to mark as relay
  */
  function _markAsRelay(address _token) internal {
    isRelay[_token] = true;
  }

  // get all fund data in one call
  function getSmartFundData() public view returns (
    address _owner,
    string _name,
    uint256 _totalShares,
    address[] _tokenAddresses,
    uint256 _successFee
  ) {
    _owner = owner;
    _name = name;
    _totalShares = totalShares;
    _tokenAddresses = tokenAddresses;
    _successFee = successFee;
  }

  /**
  * @dev Calculates the funds profit
  *
  * @return The funds profit in deposit token (Ether)
  */
  function calculateFundProfit() public view returns (int256) {
    uint256 fundValue = calculateFundValue();

    return int256(fundValue) + int256(totalWeiWithdrawn) - int256(totalWeiDeposited);
  }

  /**
  * @dev Calculates the amount of shares received according to ether deposited
  *
  * @param _amount    Amount of ether to convert to shares
  *
  * @return Amount of shares to be received
  */
  function calculateDepositToShares(uint256 _amount) public view returns (uint256) {
    uint256 fundManagerCut;
    uint256 fundValue;

    // If there are no shares in the contract, whoever deposits owns 100% of the fund
    // we will set this to 10^18 shares, but this could be any amount
    if (totalShares == 0)
      return INITIAL_SHARES;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 fundValueBeforeDeposit = fundValue.sub(_amount).sub(fundManagerCut);

    if (fundValueBeforeDeposit == 0)
      return 0;

    return _amount.mul(totalShares).div(fundValueBeforeDeposit);

  }


  /**
  * @dev Calculates the fund managers cut, depending on the funds profit and success fee
  *
  * @return fundManagerRemainingCut    The fund managers cut that they have left to withdraw
  * @return fundValue                  The funds current value
  * @return fundManagerTotalCut        The fund managers total cut of the profits until now
  */
  function calculateFundManagerCut() public view returns (
    uint256 fundManagerRemainingCut, // fm's cut of the profits that has yet to be cashed out (in `depositToken`)
    uint256 fundValue, // total value of fund (in `depositToken`)
    uint256 fundManagerTotalCut // fm's total cut of the profits (in `depositToken`)
  ) {
    fundValue = calculateFundValue();
    // The total amount of ether currently deposited into the fund, takes into account the total ether
    // withdrawn by investors as well as ether withdrawn by the fund manager
    // NOTE: value can be negative if the manager performs well and investors withdraw more
    // ether than they deposited
    int256 curtotalWeiDeposited = int256(totalWeiDeposited) - int256(totalWeiWithdrawn.add(fundManagerCashedOut));

    // If profit < 0, the fund managers totalCut and remainingCut are 0
    if (int256(fundValue) <= curtotalWeiDeposited) {
      fundManagerTotalCut = 0;
      fundManagerRemainingCut = 0;
    } else {
      // calculate profit. profit = current fund value - total deposited + total withdrawn + total withdrawn by fm
      uint256 profit = uint256(int256(fundValue) - curtotalWeiDeposited);
      // remove the money already taken by the fund manager and take percentage
      fundManagerTotalCut = profit.mul(successFee).div(TOTAL_PERCENTAGE);
      fundManagerRemainingCut = fundManagerTotalCut.sub(fundManagerCashedOut);
    }
  }

  /**
  * @dev Allows the fund manager to withdraw their cut of the funds profit
  */
  function fundManagerWithdraw() public onlyOwner {
    uint256 fundManagerCut;
    uint256 fundValue;

    (fundManagerCut, fundValue, ) = calculateFundManagerCut();

    uint256 platformCut = (platformFee == 0) ? 0 : fundManagerCut.mul(platformFee).div(TOTAL_PERCENTAGE);

    // prepare call data for _withdarw
    address[] memory spenders = new address[](2);
    spenders[0] = platformAddress;
    spenders[1] = owner;

    uint256[] memory value = new uint256[](2);
    value[0] = fundValue;
    value[1] = fundValue;

    uint256[] memory cut = new uint256[](2);
    cut[0] = platformCut;
    cut[1] = fundManagerCut - platformCut;

    // do withdraw
    _withdraw(cut, value, spenders);

    // add report
    fundManagerCashedOut = fundManagerCashedOut.add(fundManagerCut);
  }

  // calculate the current value of an address's shares in the fund
  function calculateAddressValue(address _address) public view returns (uint256) {
    if (totalShares == 0)
      return 0;

    return calculateFundValue().mul(addressToShares[_address]).div(totalShares);
  }

  // calculate the net profit/loss for an address in this fund
  function calculateAddressProfit(address _address) public view returns (int256) {
    uint256 currentAddressValue = calculateAddressValue(_address);

    return int256(currentAddressValue) - addressesNetDeposit[_address];
  }

  // This method was added to easily record the funds token balances, may (should?) be removed in the future
  function getFundTokenHolding(ERC20 _token) external view returns (uint256) {
    if (_token == ETH_TOKEN_ADDRESS)
      return address(this).balance;
    return _token.balanceOf(address(this));
  }

  /**
  * @dev Allows the manager to set whether or not only whitelisted addresses can deposit into
  * their fund
  *
  * @param _onlyWhitelist    boolean representing whether only whitelisted addresses can deposit
  */
  function setWhitelistOnly(bool _onlyWhitelist) external onlyOwner {
    onlyWhitelist = _onlyWhitelist;
  }

  /**
  * @dev Allows the fund manager to whitelist specific addresses to control
  * whos allowed to deposit into the fund
  *
  * @param _user       The user address to whitelist
  * @param _allowed    The status of _user, true means allowed to deposit, false means not allowed
  */
  function setWhitelistAddress(address _user, bool _allowed) external onlyOwner {
    whitelist[_user] = _allowed;
  }

  /**
  * @dev Allows the fund manager to connect to a new [poolPortal
  *
  * @param _newPoolPortal   The address of the new pool portal to use
  */
  function setNewPoolPortal(address _newPoolPortal) public onlyOwner {
    // Require that the new pool portal is permitted by permittedPools
    require(permittedPools.permittedAddresses(_newPoolPortal));

    poolPortal = PoolPortalInterface(_newPoolPortal);
  }

  /**
  * @dev Allows the fund manager to connect to a new exchange portal
  *
  * @param _newExchangePortalAddress    The address of the new exchange portal to use
  */
  function setNewExchangePortal(address _newExchangePortalAddress) public onlyOwner {
    // Require that the new exchange portal is permitted by permittedExchanges
    require(permittedExchanges.permittedAddresses(_newExchangePortalAddress));

    exchangePortal = ExchangePortalInterface(_newExchangePortalAddress);
  }

  /**
  * @dev This method is present in the alpha testing phase in case for some reason there are funds
  * left in the SmartFund after all shares were withdrawn
  *
  * @param _token    The address of the token to withdraw
  */
  function emergencyWithdraw(address _token) external onlyOwner {
    require(totalShares == 0);
    if (_token == address(ETH_TOKEN_ADDRESS)) {
      msg.sender.transfer(address(this).balance);
    } else {
      ERC20(_token).transfer(msg.sender, ERC20(_token).balanceOf(address(this)));
    }
  }

  /**
  * @dev Approve 0 for a certain address
  *
  * NOTE: Some ERC20 has no standard approve logic, and not allow do new approve
  * if alredy approved.
  *
  * @param _token                   address of ERC20
  * @param _spender                 address of spender
  */
  function resetApprove(address _token, address _spender) external onlyOwner {
    ERC20(_token).approve(_spender, 0);
  }

  // Fallback payable function in order to be able to receive ether from other contracts
  function() public payable {}

  /**
    **************************** ERC20 Compliance ****************************
  **/

  // Note that addressesNetDeposit does not get updated when transferring shares, since
  // this is used for updating off-chain data it doesn't affect the smart contract logic,
  // but is an issue that currently exists

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);

  uint8 public decimals = 18;

  string public symbol = "FND";

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
  * @dev Total number of shares in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalShares;
  }

  /**
  * @dev Gets the balance of the specified address.
  *
  * @param _who    The address to query the the balance of.
  *
  * @return A uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _who) public view returns (uint256) {
    return addressToShares[_who];
  }

  /**
  * @dev Transfer shares for a specified address
  *
  * @param _to       The address to transfer to.
  * @param _value    The amount to be transferred.
  *
  * @return true upon success
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[msg.sender]);

    addressToShares[msg.sender] = addressToShares[msg.sender].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Transfer shares from one address to another
   *
   * @param _from     The address which you want to send tokens from
   * @param _to       The address which you want to transfer to
   * @param _value    The amount of shares to be transferred
   *
   * @return true upon success
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= addressToShares[_from]);
    require(_value <= allowed[_from][msg.sender]);

    addressToShares[_from] = addressToShares[_from].sub(_value);
    addressToShares[_to] = addressToShares[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of shares on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _spender    The address which will spend the funds.
   * @param _value      The amount of shares to be spent.
   *
   * @return true upon success
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of shares that an owner allowed to a spender.
   *
   * @param _owner      The address which owns the funds.
   * @param _spender    The address which will spend the funds.
   *
   * @return A uint256 specifying the amount of shares still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}


contract SmartFundAdvanced is SmartFundCore {
  using SafeMath for uint256;

  CEther public cEther;
  mapping(address => bool) public isCTOKEN;
  address[] public compoundTokenAddresses;


  /**
  * @dev constructor
  * @param _owner                        Owner of new smart fund
  * @param _name                         Name of new smart fund
  * @param _successFee                   Initial success fee
  * @param _platformFee                  Initial platform fee
  * @param _platformAddress              Address of smart fund registry
  * @param _exchangePortalAddress        Address of the initial ExchangePortal contract
  * @param _permittedExchangesAddress    Address of the permittedExchanges contract
  * @param _poolPortalAddress            Address of the initial PoolPortal contract
  * @param _permittedPoolsAddress        Address of the permittedPool contract
  * @param _cEther                       Address of the cEther
  */
  constructor(
    address _owner,
    string  _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platformAddress,
    address _exchangePortalAddress,
    address _permittedExchangesAddress,
    address _permittedPoolsAddress,
    address _poolPortalAddress,
    address _cEther
  )
  SmartFundCore(
    _owner,
    _name,
    _successFee,
    _platformFee,
    _platformAddress,
    _exchangePortalAddress,
    _permittedExchangesAddress,
    _permittedPoolsAddress,
    _poolPortalAddress
  )
  public
  {
    cEther = CEther(_cEther);
  }


  /**
  * @dev buy Compound cTokens
  *
  * @param _amount       amount of ERC20 or ETH
  * @param _cToken       cToken address
  */
  function compoundMint(uint256 _amount, address _cToken) external onlyOwner{
    if(_cToken == address(cEther)){
      // mint cETH
      cEther.mint.value(_amount)();
      // Add token to ERC list
      _addToken(address(cEther));
      // Add to c token list
      _addCompoundToken(address(cEther));
    }else{
      CToken cToken = CToken(_cToken);
      address underlyingAddress = cToken.underlying();
      ERC20(underlyingAddress).approve(address(_cToken), _amount);
      // mint cERC
      cToken.mint(_amount);
      // Add cToken
      _addToken(_cToken);
      // Add to c token list
      _addCompoundToken(_cToken);
    }
  }

  /**
  * @dev sell certain percent of Ctokens to Compound
  *
  * @param _percent      percent from 1 to 100
  * @param _cToken       cToken address
  */
  function compoundRedeemByPercent(uint _percent, address _cToken) external onlyOwner {
    uint256 amount = (_percent == 100)
    // if 100 return all
    ? ERC20(address(_cToken)).balanceOf(address(this))
    // else calculate percent
    : getPercentFromCTokenBalance(_percent, address(_cToken));

    if(_cToken == address(cEther)){
      cEther.redeem(amount);
    }else{
      CToken cToken = CToken(_cToken);
      cToken.redeem(amount);
    }
  }


  /**
  * @dev return percent of compound cToken balance
  *
  * @param _percent       amount of ERC20 or ETH
  * @param _cToken       cToken address
  */
  function getPercentFromCTokenBalance(uint _percent, address _cToken)
  public
  view
  returns(uint256)
  {
    if(_percent > 0 && _percent <= 100){
      uint256 currectBalance = ERC20(_cToken).balanceOf(address(this));
      return currectBalance.div(100).mul(_percent);
    }
    else{
      // not correct percent
      revert();
    }
  }

  /**
  * @dev sell Compound cToken by cToken amount
  *
  * @param _amount       amount of ERC20 or ETH
  * @param _cToken       cToken address
  */
  function compoundRedeem(uint256 _amount, address _cToken) external onlyOwner {
    if(_cToken == address(cEther)){
      cEther.redeem(_amount);
    }else{
      CToken cToken = CToken(_cToken);
      cToken.redeem(_amount);
    }
  }

  /**
  * @dev sell Compound cToken by underlying (ERC20 or ETH) amount
  *
  * @param _amount       amount of ERC20 or ETH
  * @param _cToken       cToken address
  */
  function compoundRedeemUnderlying(uint256 _amount, address _cToken) external onlyOwner {
    if(_cToken == address(cEther)){
      cEther.redeemUnderlying(_amount);
    }else{
      CToken cToken = CToken(_cToken);
      cToken.redeemUnderlying(_amount);
    }
  }

  /**
  * @dev get value for cToken in base asset (ERC20 or ETH) ratio for this smart fund address
  *
  * @param _cToken       cToken address
  */
  function compoundGetCTokenValue(
    address _cToken
  )
    public
    view
    returns(uint256 result)
  {
    result = CToken(_cToken).balanceOfUnderlying(address(this));
  }

  /**
  * @dev get value for all cTokens for this smart fund address in ETH ratio
  *
  */
  function compoundGetAllFundCtokensinETH()
    public
    view
    returns(uint256)
  {
    if(compoundTokenAddresses.length > 0){
      uint256 balance = 0;
      for (uint256 i = 0; i < compoundTokenAddresses.length; i++) {
        balance = balance.add(compoundGetCTokenValue(compoundTokenAddresses[i]));
      }
      return balance;
    }
    else{
      return 0;
    }
  }

  function _addCompoundToken(address _cToken) private {
    if(!isCTOKEN[_cToken]){
      // Mark this tokens as Ctoken
      isCTOKEN[_cToken] = true;
      // Add compound token
      compoundTokenAddresses.push(_cToken);
    }
  }

  // return length of all trade available Compound tokens in fund
  function compoundCTokensLength() public view returns(uint){
    uint8 count;
    for (uint8 i = 1; i < tokenAddresses.length; i++) {
      if(isCTOKEN[tokenAddresses[i]])
        count++;
    }

    return count;
  }

}



contract SmartFundETHInterface is SmartFundInterface{
  // deposit `amount` of tokens.
  // returns number of shares the user receives
  function deposit() external payable returns (uint256);
}


/*
  Note: this smart fund inherits SmartFundAdvanced and make core operations like deposit,
  calculate fund value etc in ETH
*/
contract SmartFundETH is SmartFundETHInterface, SmartFundAdvanced {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  /**
  * @dev constructor
  *
  * @param _owner                        Address of the fund manager
  * @param _name                         Name of the fund, required for DetailedERC20 compliance
  * @param _successFee                   Percentage of profit that the fund manager receives
  * @param _platformFee                  Percentage of the success fee that goes to the platform
  * @param _platformAddress              Address of platform to send fees to
  * @param _exchangePortalAddress        Address of initial exchange portal
  * @param _permittedExchangesAddress    Address of PermittedExchanges contract
  * @param _permittedPoolsAddress        Address of PermittedPools contract
  * @param _poolPortalAddress            Address of initial pool portal
  * @param _cEther                       Address of the cEther
  */
  constructor(
    address _owner,
    string _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platformAddress,
    address _exchangePortalAddress,
    address _permittedExchangesAddress,
    address _permittedPoolsAddress,
    address _poolPortalAddress,
    address _cEther
  )
  SmartFundAdvanced(
    _owner,
    _name,
    _successFee,
    _platformFee,
    _platformAddress,
    _exchangePortalAddress,
    _permittedExchangesAddress,
    _permittedPoolsAddress,
    _poolPortalAddress,
    _cEther
  )
  public{}

  /**
  * @dev Deposits ether into the fund and allocates a number of shares to the sender
  * depending on the current number of shares, the funds value, and amount deposited
  *
  * @return The amount of shares allocated to the depositor
  */
  function deposit() external payable returns (uint256) {
    // Check if the sender is allowed to deposit into the fund
    if (onlyWhitelist)
      require(whitelist[msg.sender]);

    // Require that the amount sent is not 0
    require(msg.value != 0);

    totalWeiDeposited += msg.value;

    // Calculate number of shares
    uint256 shares = calculateDepositToShares(msg.value);

    // If user would receive 0 shares, don't continue with deposit
    require(shares != 0);

    // Add shares to total
    totalShares = totalShares.add(shares);

    // Add shares to address
    addressToShares[msg.sender] = addressToShares[msg.sender].add(shares);

    addressesNetDeposit[msg.sender] += int256(msg.value);

    emit Deposit(msg.sender, msg.value, shares, totalShares);

    return shares;
  }

  /**
  * @dev Calculates the funds value in deposit token (Ether)
  *
  * @return The current total fund value
  */
  function calculateFundValue() public view returns (uint256) {
    uint256 ethBalance = address(this).balance;

    // If the fund only contains ether, return the funds ether balance
    if (tokenAddresses.length == 1)
      return ethBalance;

    // Otherwise, we get the value of all the other tokens in ether via exchangePortal

    // Calculate value for ERC20
    // Sub cTokens + ETH
    uint cTokensAndETHlength = compoundCTokensLength() + 1;
    address[] memory fromAddresses = new address[](tokenAddresses.length - cTokensAndETHlength);
    uint256[] memory amounts = new uint256[](tokenAddresses.length - cTokensAndETHlength);
    uint8 ercIndex = 0;

    for (uint256 i = 1; i < tokenAddresses.length; i++) {
      // No need for cToken
      if(!isCTOKEN[tokenAddresses[i]]){
        fromAddresses[ercIndex] = tokenAddresses[i];
        amounts[ercIndex] = ERC20(tokenAddresses[i]).balanceOf(address(this));
        ercIndex++;
      }
    }
    // Ask the Exchange Portal for the value of all the funds tokens in eth
    uint256 tokensValue = exchangePortal.getTotalValue(fromAddresses, amounts, ETH_TOKEN_ADDRESS);

    // get compound c tokens in ETH
    uint256 compoundCTokensValueInETH = compoundGetAllFundCtokensinETH();

    // Sum ETH + ERC20 + cTokens
    return ethBalance + tokensValue + compoundCTokensValueInETH;
  }

  /**
  * @dev get balance of input asset address in ETH ratio
  *
  * @param _token     token address
  *
  * @return balance in ETH
  */
  function getTokenValue(ERC20 _token) public view returns (uint256) {
    // return ETH
    if (_token == ETH_TOKEN_ADDRESS){
      return address(this).balance;
    }
    // return CToken in ETH
    else if(isCTOKEN[_token]){
      return compoundGetCTokenValue(_token);
    }
    // return ERC20 in ETH
    else{
      uint256 tokenBalance = _token.balanceOf(address(this));
      return exchangePortal.getValue(_token, ETH_TOKEN_ADDRESS, tokenBalance);
    }
  }
}


contract SmartFundETHFactory {
  function createSmartFund(
    address _owner,
    string  _name,
    uint256 _successFee,
    uint256 _platformFee,
    address _platfromAddress,
    address _exchangePortalAddress,
    address _permittedExchanges,
    address _permittedPools,
    address _poolPortalAddress,
    address _cEther
    )
  public
  returns(address)
  {
    SmartFundETH smartFundETH = new SmartFundETH(
      _owner,
      _name,
      _successFee,
      _platformFee,
      _platfromAddress,
      _exchangePortalAddress,
      _permittedExchanges,
      _permittedPools,
      _poolPortalAddress,
      _cEther
    );

    return address(smartFundETH);
  }
}
