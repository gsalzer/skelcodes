
// File: solidity/contracts/utility/interfaces/IOwned.sol

pragma solidity 0.4.26;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

// File: solidity/contracts/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol

pragma solidity 0.4.26;



/*
    Token Holder interface
*/
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol

pragma solidity 0.4.26;



/*
    Converter Anchor interface
*/
contract IConverterAnchor is IOwned, ITokenHolder {
}

// File: solidity/contracts/token/interfaces/ISmartToken.sol

pragma solidity 0.4.26;




/*
    Smart Token interface
*/
contract ISmartToken is IConverterAnchor, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/interfaces/IPoolTokensContainer.sol

pragma solidity 0.4.26;



/*
    Pool Tokens Container interface
*/
contract IPoolTokensContainer is IConverterAnchor {
    function poolTokens() public view returns (ISmartToken[]);
    function createToken() public returns (ISmartToken);
    function mint(ISmartToken _token, address _to, uint256 _amount) public;
    function burn(ISmartToken _token, address _from, uint256 _amount) public;
}

// File: solidity/contracts/utility/Owned.sol

pragma solidity 0.4.26;

/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol

pragma solidity 0.4.26;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: solidity/contracts/utility/TokenHandler.sol

pragma solidity 0.4.26;


contract TokenHandler {
    bytes4 private constant APPROVE_FUNC_SELECTOR = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant TRANSFER_FUNC_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant TRANSFER_FROM_FUNC_SELECTOR = bytes4(keccak256("transferFrom(address,address,uint256)"));

    /**
      * @dev executes the ERC20 token's `approve` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _spender approved address
      * @param _value   allowance amount
    */
    function safeApprove(IERC20Token _token, address _spender, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(APPROVE_FUNC_SELECTOR, _spender, _value));
    }

    /**
      * @dev executes the ERC20 token's `transfer` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransfer(IERC20Token _token, address _to, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(TRANSFER_FUNC_SELECTOR, _to, _value));
    }

    /**
      * @dev executes the ERC20 token's `transferFrom` function and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    function safeTransferFrom(IERC20Token _token, address _from, address _to, uint256 _value) internal {
       execute(_token, abi.encodeWithSelector(TRANSFER_FROM_FUNC_SELECTOR, _from, _to, _value));
    }

    /**
      * @dev executes a function on the ERC20 token and reverts upon failure
      * the main purpose of this function is to prevent a non standard ERC20 token
      * from failing silently
      *
      * @param _token   ERC20 token address
      * @param _data    data to pass in to the token's contract for execution
    */
    function execute(IERC20Token _token, bytes memory _data) private {
        uint256[1] memory ret = [uint256(1)];

        assembly {
            let success := call(
                gas,            // gas remaining
                _token,         // destination address
                0,              // no ether
                add(_data, 32), // input buffer (starts after the first 32 bytes in the `data` array)
                mload(_data),   // input length (loaded from the first 32 bytes in the `data` array)
                ret,            // output buffer
                32              // output length
            )
            if iszero(success) {
                revert(0, 0)
            }
        }

        require(ret[0] != 0, "ERR_TRANSFER_FAILED");
    }
}

// File: solidity/contracts/utility/TokenHolder.sol

pragma solidity 0.4.26;

/**
  * @dev We consider every contract to be a 'token holder' since it's currently not possible
  * for a contract to deny receiving tokens.
  *
  * The TokenHolder's contract sole purpose is to provide a safety mechanism that allows
  * the owner to send tokens that were sent to the contract by mistake back to their sender.
  *
  * Note that we use the non standard ERC-20 interface which has no return value for transfer
  * in order to support both non standard as well as standard token contracts.
  * see https://github.com/ethereum/solidity/issues/4116
*/
contract TokenHolder is ITokenHolder, TokenHandler, Owned, Utils {
    /**
      * @dev withdraws tokens held by the contract and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        safeTransfer(_token, _to, _amount);
    }
}

// File: solidity/contracts/utility/SafeMath.sol

pragma solidity 0.4.26;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}

// File: solidity/contracts/token/ERC20Token.sol

pragma solidity 0.4.26;

/**
  * @dev ERC20 Standard Token implementation
*/
contract ERC20Token is IERC20Token, Utils {
    using SafeMath for uint256;


    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /**
      * @dev triggered when tokens are transferred between wallets
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
      * @dev triggered when a wallet allows another wallet to transfer tokens from on its behalf
      *
      * @param _owner   wallet that approves the allowance
      * @param _spender wallet that receives the allowance
      * @param _value   allowance amount
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
      * @dev initializes a new ERC20Token instance
      *
      * @param _name        token name
      * @param _symbol      token symbol
      * @param _decimals    decimal points, for display purposes
      * @param _totalSupply total supply of token units
    */
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        // validate input
        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    /**
      * @dev transfers tokens to a given address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
      * @dev transfers tokens to a given address on behalf of another address
      * throws on any error rather then return a false flag to minimize user errors
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
      * @dev allows another account/contract to transfers tokens on behalf of the caller
      * throws on any error rather then return a false flag to minimize user errors
      *
      * also, to minimize the risk of the approve/transferFrom attack vector
      * (see https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/), approve has to be called twice
      * in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value
      *
      * @param _spender approved address
      * @param _value   allowance amount
      *
      * @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0, "ERR_INVALID_AMOUNT");

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
}

// File: solidity/contracts/token/SmartToken.sol

pragma solidity 0.4.26;

/**
  * @dev Smart Token
  *
  * 'Owned' is specified here for readability reasons
*/
contract SmartToken is ISmartToken, Owned, ERC20Token, TokenHolder {
    using SafeMath for uint256;

    uint16 public constant version = 4;

    bool public transfersEnabled = true;    // true if transfer/transferFrom are enabled, false otherwise

    /**
      * @dev triggered when the total supply is increased
      *
      * @param _amount  amount that gets added to the supply
    */
    event Issuance(uint256 _amount);

    /**
      * @dev triggered when the total supply is decreased
      *
      * @param _amount  amount that gets removed from the supply
    */
    event Destruction(uint256 _amount);

    /**
      * @dev initializes a new SmartToken instance
      *
      * @param _name       token name
      * @param _symbol     token short symbol, minimum 1 character
      * @param _decimals   for display purposes only
    */
    constructor(string _name, string _symbol, uint8 _decimals)
        public
        ERC20Token(_name, _symbol, _decimals, 0)
    {
    }

    // allows execution only when transfers are enabled
    modifier transfersAllowed {
        _transfersAllowed();
        _;
    }

    // error message binary size optimization
    function _transfersAllowed() internal view {
        require(transfersEnabled, "ERR_TRANSFERS_DISABLED");
    }

    /**
      * @dev disables/enables transfers
      * can only be called by the contract owner
      *
      * @param _disable    true to disable transfers, false to enable them
    */
    function disableTransfers(bool _disable) public ownerOnly {
        transfersEnabled = !_disable;
    }

    /**
      * @dev increases the token supply and sends the new tokens to the given account
      * can only be called by the contract owner
      *
      * @param _to      account to receive the new amount
      * @param _amount  amount to increase the supply by
    */
    function issue(address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_to)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Issuance(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
      * @dev removes tokens from the given account and decreases the token supply
      * can only be called by the contract owner
      *
      * @param _from    account to remove the amount from
      * @param _amount  amount to decrease the supply by
    */
    function destroy(address _from, uint256 _amount) public ownerOnly {
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Destruction(_amount);
    }

    // ERC20 standard method overrides with some extra functionality

    /**
      * @dev send coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transfer(_to, _value));
        return true;
    }

    /**
      * @dev an account/contract attempts to get the coins
      * throws on any error rather then return a false flag to minimize user errors
      * in addition to the standard checks, the function throws if transfers are disabled
      *
      * @param _from    source address
      * @param _to      target address
      * @param _value   transfer amount
      *
      * @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool success) {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/PoolTokensContainer.sol

pragma solidity 0.4.26;

/**
  * @dev The PoolTokensContainer contract serves as a container for multiple pool tokens.
  * It is used by specific liquidity pool types that require more than a single pool token,
  * while still maintaining the single converter / anchor relationship.
  *
  * It maintains and provides a list of the underlying pool tokens.
 */
contract PoolTokensContainer is IPoolTokensContainer, Owned, TokenHolder {
    uint8 internal constant MAX_POOL_TOKENS = 5;    // maximum pool tokens in the container

    string public name;                 // pool name
    string public symbol;               // pool symbol
    uint8 public decimals;              // underlying pool tokens decimals
    ISmartToken[] private _poolTokens;  // underlying pool tokens

    /**
      * @dev initializes a new PoolTokensContainer instance
      *
      * @param  _name       pool name, also used as a prefix for the underlying pool token names
      * @param  _symbol     pool symbol, also used as a prefix for the underlying pool token symbols
      * @param  _decimals   used for the underlying pool token decimals
    */
    constructor(string _name, string _symbol, uint8 _decimals) public {
         // validate input
        require(bytes(_name).length > 0, "ERR_INVALID_NAME");
        require(bytes(_symbol).length > 0, "ERR_INVALID_SYMBOL");

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
      * @dev returns the list of pool tokens
      *
      * @return list of pool tokens
    */
    function poolTokens() public view returns (ISmartToken[] memory) {
        return _poolTokens;
    }

    /**
      * @dev creates a new pool token and adds it to the list
      *
      * @return new pool token address
    */
    function createToken() public ownerOnly returns (ISmartToken) {
        // verify that the max limit wasn't reached
        require(_poolTokens.length < MAX_POOL_TOKENS, "ERR_MAX_LIMIT_REACHED");

        string memory poolName = concatStrDigit(name, uint8(_poolTokens.length + 1));
        string memory poolSymbol = concatStrDigit(symbol, uint8(_poolTokens.length + 1));

        SmartToken token = new SmartToken(poolName, poolSymbol, decimals);
        _poolTokens.push(token);
        return token;
    }

    /**
      * @dev increases the pool token supply and sends the new tokens to the given account
      * can only be called by the contract owner
      *
      * @param _token   pool token address
      * @param _to      account to receive the newly minted tokens
      * @param _amount  amount to mint
    */
    function mint(ISmartToken _token, address _to, uint256 _amount) public ownerOnly {
        _token.issue(_to, _amount);
    }

    /**
      * @dev removes tokens from the given account and decreases the pool token supply
      * can only be called by the contract owner
      *
      * @param _token   pool token address
      * @param _from    account to remove the tokens from
      * @param _amount  amount to burn
    */
    function burn(ISmartToken _token, address _from, uint256 _amount) public ownerOnly {
        _token.destroy(_from, _amount);
    }

    /**
      * @dev concatenates a string and a digit (single only) and returns the result string
      *
      * @param _str     string
      * @param _digit   digit
      * @return concatenated string
    */
    function concatStrDigit(string _str, uint8 _digit) private pure returns (string) {
        return string(abi.encodePacked(_str, uint8(bytes1('0')) + _digit));
    }
}

// File: solidity/contracts/converter/interfaces/ITypedConverterCustomFactory.sol

pragma solidity 0.4.26;

/*
    Typed Converter Custom Factory interface
*/
contract ITypedConverterCustomFactory {
    function converterType() public pure returns (uint16);
}

// File: solidity/contracts/utility/interfaces/IChainlinkPriceOracle.sol

pragma solidity 0.4.26;

/*
    Chainlink Price Oracle interface
*/
interface IChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

// File: solidity/contracts/utility/interfaces/IPriceOracle.sol

pragma solidity 0.4.26;



/*
    Price Oracle interface
*/
contract IPriceOracle {
    function latestRate(IERC20Token _tokenA, IERC20Token _tokenB) public view returns (uint256, uint256);
    function lastUpdateTime() public view returns (uint256);
    function latestRateAndUpdateTime(IERC20Token _tokenA, IERC20Token _tokenB) public view returns (uint256, uint256, uint256);

    function tokenAOracle() public view returns (IChainlinkPriceOracle) {this;}
    function tokenBOracle() public view returns (IChainlinkPriceOracle) {this;}
}

// File: solidity/contracts/utility/PriceOracle.sol

pragma solidity 0.4.26;

/**
  * @dev Provides the off-chain rate between two tokens
  *
  * The price oracle uses chainlink oracles internally to get the rates of the two tokens
  * with respect to a common denominator, and then returns the rate between them, which
  * is equivalent to the rate of TokenA / TokenB
*/
contract PriceOracle is IPriceOracle, Utils {
    using SafeMath for uint256;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint8 private constant ETH_DECIMALS = 18;

    IERC20Token public tokenA;                  // token A the oracle supports
    IERC20Token public tokenB;                  // token B the oracle supports
    mapping (address => uint8) public tokenDecimals; // token -> token decimals

    IChainlinkPriceOracle public tokenAOracle;  // token A chainlink price oracle
    IChainlinkPriceOracle public tokenBOracle;  // token B chainlink price oracle
    mapping (address => IChainlinkPriceOracle) public tokensToOracles;  // token -> price oracle for easier access

    /**
      * @dev initializes a new PriceOracle instance
      * note that the oracles must have the same common denominator (USD, ETH etc.)
      *
      * @param  _tokenA         first token to support
      * @param  _tokenB         second token to support
      * @param  _tokenAOracle   first token price oracle
      * @param  _tokenBOracle   second token price oracle
    */
    constructor(IERC20Token _tokenA, IERC20Token _tokenB, IChainlinkPriceOracle _tokenAOracle, IChainlinkPriceOracle _tokenBOracle)
        public
        validUniqueAddresses(_tokenA, _tokenB)
        validUniqueAddresses(_tokenAOracle, _tokenBOracle)
    {
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenDecimals[_tokenA] = decimals(_tokenA);
        tokenDecimals[_tokenB] = decimals(_tokenB);

        tokenAOracle = _tokenAOracle;
        tokenBOracle = _tokenBOracle;
        tokensToOracles[_tokenA] = _tokenAOracle;
        tokensToOracles[_tokenB] = _tokenBOracle;
    }

    // ensures that the provided addresses are unique valid
    modifier validUniqueAddresses(address _address1, address _address2) {
        _validUniqueAddresses(_address1, _address2);
        _;
    }

    // error message binary size optimization
    function _validUniqueAddresses(address _address1, address _address2) internal pure {
        _validAddress(_address1);
        _validAddress(_address2);
        require(_address1 != _address2, "ERR_SAME_ADDRESS");
    }

    // ensures that the provides tokens are supported by the oracle
    modifier supportedTokens(IERC20Token _tokenA, IERC20Token _tokenB) {
        _supportedTokens(_tokenA, _tokenB);
        _;
    }

    // error message binary size optimization
    function _supportedTokens(IERC20Token _tokenA, IERC20Token _tokenB) internal view {
        _validUniqueAddresses(_tokenA, _tokenB);
        require(tokensToOracles[_tokenA] != address(0) && tokensToOracles[_tokenB] != address(0), "ERR_UNSUPPORTED_TOKEN");
    }

    /**
      * @dev returns the latest known rate between the two given tokens
      * for a given pair of tokens A and B, returns the rate of A / B
      * (the number of B units equivalent to a single A unit)
      * the rate is returned as a fraction (numerator / denominator) for accuracy
      *
      * @param  _tokenA token to get the rate of 1 unit of
      * @param  _tokenB token to get the rate of 1 `_tokenA` against
      *
      * @return numerator
      * @return denominator
    */
    function latestRate(IERC20Token _tokenA, IERC20Token _tokenB)
        public
        view
        supportedTokens(_tokenA, _tokenB)
        returns (uint256, uint256)
    {
        uint256 rateTokenA = uint256(tokensToOracles[_tokenA].latestAnswer());
        uint256 rateTokenB = uint256(tokensToOracles[_tokenB].latestAnswer());
        uint8 decimalsTokenA = tokenDecimals[_tokenA];
        uint8 decimalsTokenB = tokenDecimals[_tokenB];

        // the normalization works as follows:
        //   - token A with decimals of dA and price of rateA per one token (e.g., for 10^dA weiA)
        //   - token B with decimals of dB < dA and price of rateB per one token (e.g., for 10^dB weiB)
        // then the normalized rate, representing the rate between 1 weiA and 1 weiB is rateA / (rateB * 10^(dA - dB)).
        //
        // for example:
        //   - token A with decimals of 5 and price of $10 per one token (e.g., for 100,000 weiA)
        //   - token B with decimals of 2 and price of $2 per one token (e.g., for 100 weiB)
        // then the normalized rate would be: 5 / (2 * 10^3) = 0.0025, which is the correct rate since
        // 1 weiA costs $0.00005, 1 weiB costs $0.02, and weiA / weiB is 0.0025.

        if (decimalsTokenA > decimalsTokenB) {
            rateTokenB = rateTokenB.mul(uint256(10) ** (decimalsTokenA - decimalsTokenB));
        }
        else if (decimalsTokenA < decimalsTokenB) {
            rateTokenA = rateTokenA.mul(uint256(10) ** (decimalsTokenB - decimalsTokenA));
        }

        return (rateTokenA, rateTokenB);
    }

    /**
      * @dev returns the timestamp of the last price update the rates are returned as numerator (token1) and denominator
      * (token2) for accuracy
      *
      * @return timestamp
    */
    function lastUpdateTime()
        public
        view
        returns (uint256) {
        // returns the oldest timestamp between the two
        uint256 timestampA = tokenAOracle.latestTimestamp();
        uint256 timestampB = tokenBOracle.latestTimestamp();

        return  timestampA < timestampB ? timestampA : timestampB;
    }

    /**
      * @dev returns both the rate and the timestamp of the last update in a single call (gas optimization)
      *
      * @param  _tokenA token to get the rate of 1 unit of
      * @param  _tokenB token to get the rate of 1 `_tokenA` against
      *
      * @return numerator
      * @return denominator
      * @return timestamp of the last update
    */
    function latestRateAndUpdateTime(IERC20Token _tokenA, IERC20Token _tokenB)
        public
        view
        returns (uint256, uint256, uint256)
    {
        (uint256 numerator, uint256 denominator) = latestRate(_tokenA, _tokenB);

        return (numerator, denominator, lastUpdateTime());
    }

    /** @dev returns the decimals of a given token */
    function decimals(IERC20Token _token) private view returns (uint8) {
        if (_token == ETH_ADDRESS) {
            return ETH_DECIMALS;
        }

        return _token.decimals();
    }
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/LiquidityPoolV2ConverterCustomFactory.sol

pragma solidity 0.4.26;

/*
    LiquidityPoolV2ConverterCustomFactory Factory
*/
contract LiquidityPoolV2ConverterCustomFactory is ITypedConverterCustomFactory {
    /**
      * @dev returns the converter type the factory is associated with
      *
      * @return converter type
    */
    function converterType() public pure returns (uint16) {
        return 2;
    }

    /**
      * @dev creates a new price oracle
      * note that the oracles must have the same common denominator (USD, ETH etc.)
      *
      * @param  _primaryReserveToken    primary reserve token address
      * @param  _secondaryReserveToken  secondary reserve token address
      * @param  _primaryReserveOracle   primary reserve oracle address
      * @param  _secondaryReserveOracle secondary reserve oracle address
    */
    function createPriceOracle(
        IERC20Token _primaryReserveToken,
        IERC20Token _secondaryReserveToken,
        IChainlinkPriceOracle _primaryReserveOracle,
        IChainlinkPriceOracle _secondaryReserveOracle)
        public
        returns (IPriceOracle)
    {
        return new PriceOracle(_primaryReserveToken, _secondaryReserveToken, _primaryReserveOracle, _secondaryReserveOracle);
    }
}

// File: solidity/contracts/utility/interfaces/IWhitelist.sol

pragma solidity 0.4.26;

/*
    Whitelist interface
*/
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

// File: solidity/contracts/converter/interfaces/IConverter.sol

pragma solidity 0.4.26;





/*
    Converter interface
*/
contract IConverter is IOwned {
    function converterType() public pure returns (uint16);
    function anchor() public view returns (IConverterAnchor) {this;}
    function isActive() public view returns (bool);

    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) public view returns (uint256, uint256);
    function convert(IERC20Token _sourceToken,
                     IERC20Token _targetToken,
                     uint256 _amount,
                     address _trader,
                     address _beneficiary) public payable returns (uint256);

    function conversionWhitelist() public view returns (IWhitelist) {this;}
    function conversionFee() public view returns (uint32) {this;}
    function maxConversionFee() public view returns (uint32) {this;}
    function reserveBalance(IERC20Token _reserveToken) public view returns (uint256);
    function() external payable;

    function transferAnchorOwnership(address _newOwner) public;
    function acceptAnchorOwnership() public;
    function setConversionFee(uint32 _conversionFee) public;
    function setConversionWhitelist(IWhitelist _whitelist) public;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
    function withdrawETH(address _to) public;
    function addReserve(IERC20Token _token, uint32 _ratio) public;

    // deprecated, backward compatibility
    function token() public view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) public;
    function acceptTokenOwnership() public;
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function connectorTokens(uint256 _index) public view returns (IERC20Token);
    function connectorTokenCount() public view returns (uint16);
}

// File: solidity/contracts/converter/interfaces/IConverterUpgrader.sol

pragma solidity 0.4.26;

/*
    Converter Upgrader interface
*/
contract IConverterUpgrader {
    function upgrade(bytes32 _version) public;
    function upgrade(uint16 _version) public;
}

// File: solidity/contracts/converter/interfaces/IBancorFormula.sol

pragma solidity 0.4.26;

/*
    Bancor Formula interface
*/
contract IBancorFormula {
    function purchaseTargetAmount(uint256 _supply,
                                  uint256 _reserveBalance,
                                  uint32 _reserveWeight,
                                  uint256 _amount)
                                  public view returns (uint256);

    function saleTargetAmount(uint256 _supply,
                              uint256 _reserveBalance,
                              uint32 _reserveWeight,
                              uint256 _amount)
                              public view returns (uint256);

    function crossReserveTargetAmount(uint256 _sourceReserveBalance,
                                      uint32 _sourceReserveWeight,
                                      uint256 _targetReserveBalance,
                                      uint32 _targetReserveWeight,
                                      uint256 _amount)
                                      public view returns (uint256);

    function fundCost(uint256 _supply,
                      uint256 _reserveBalance,
                      uint32 _reserveRatio,
                      uint256 _amount)
                      public view returns (uint256);

    function fundSupplyAmount(uint256 _supply,
                              uint256 _reserveBalance,
                              uint32 _reserveRatio,
                              uint256 _amount)
                              public view returns (uint256);

    function liquidateReserveAmount(uint256 _supply,
                                    uint256 _reserveBalance,
                                    uint32 _reserveRatio,
                                    uint256 _amount)
                                    public view returns (uint256);

    function balancedWeights(uint256 _primaryReserveStakedBalance,
                             uint256 _primaryReserveBalance,
                             uint256 _secondaryReserveBalance,
                             uint256 _reserveRateNumerator,
                             uint256 _reserveRateDenominator)
                             public view returns (uint32, uint32);
}

// File: solidity/contracts/IBancorNetwork.sol

pragma solidity 0.4.26;


/*
    Bancor Network interface
*/
contract IBancorNetwork {
    function convert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    function convertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    // deprecated, backward compatibility
    function convert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public payable returns (uint256);

    // deprecated, backward compatibility
    function claimAndConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public returns (uint256);

    // deprecated, backward compatibility
    function convertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public payable returns (uint256);

    // deprecated, backward compatibility
    function claimAndConvertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public returns (uint256);
}

// File: solidity/contracts/utility/interfaces/IContractRegistry.sol

pragma solidity 0.4.26;

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}

// File: solidity/contracts/utility/ContractRegistryClient.sol

pragma solidity 0.4.26;

/**
  * @dev Base contract for ContractRegistry clients
*/
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant CHAINLINK_ORACLE_WHITELIST = "ChainlinkOracleWhitelist";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
    bool public onlyOwnerCanUpdateRegistry; // only an owner can update the contract-registry

    /**
      * @dev verifies that the caller is mapped to the given contract name
      *
      * @param _contractName    contract name
    */
    modifier only(bytes32 _contractName) {
        _only(_contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 _contractName) internal view {
        require(msg.sender == addressOf(_contractName), "ERR_ACCESS_DENIED");
    }

    /**
      * @dev initializes a new ContractRegistryClient instance
      *
      * @param  _registry   address of a contract-registry contract
    */
    constructor(IContractRegistry _registry) internal validAddress(_registry) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
      * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(msg.sender == owner || !onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract-registry
        IContractRegistry newRegistry = IContractRegistry(addressOf(CONTRACT_REGISTRY));

        // verify that the new contract-registry is different and not zero
        require(newRegistry != address(registry) && newRegistry != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = newRegistry;
    }

    /**
      * @dev restores the previous contract-registry
    */
    function restoreRegistry() public ownerOnly {
        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
      * @dev restricts the permission to update the contract-registry
      *
      * @param _onlyOwnerCanUpdateRegistry  indicates whether or not permission is restricted to owner only
    */
    function restrictRegistryUpdate(bool _onlyOwnerCanUpdateRegistry) public ownerOnly {
        // change the permission to update the contract-registry
        onlyOwnerCanUpdateRegistry = _onlyOwnerCanUpdateRegistry;
    }

    /**
      * @dev returns the address associated with the given contract name
      *
      * @param _contractName    contract name
      *
      * @return contract address
    */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: solidity/contracts/utility/ReentrancyGuard.sol

pragma solidity 0.4.26;

/**
  * @dev ReentrancyGuard
  *
  * The contract provides protection against re-entrancy - calling a function (directly or
  * indirectly) from within itself.
*/
contract ReentrancyGuard {
    // true while protected code is being executed, false otherwise
    bool private locked = false;

    /**
      * @dev ensures instantiation only by sub-contracts
    */
    constructor() internal {}

    // protects a function against reentrancy attacks
    modifier protected() {
        _protected();
        locked = true;
        _;
        locked = false;
    }

    // error message binary size optimization
    function _protected() internal view {
        require(!locked, "ERR_REENTRANCY");
    }
}

// File: solidity/contracts/token/interfaces/IEtherToken.sol

pragma solidity 0.4.26;


/*
    Ether Token interface
*/
contract IEtherToken is IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function depositTo(address _to) public payable;
    function withdrawTo(address _to, uint256 _amount) public;
}

// File: solidity/contracts/bancorx/interfaces/IBancorX.sol

pragma solidity 0.4.26;


contract IBancorX {
    function token() public view returns (IERC20Token) {this;}
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public;
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256);
}

// File: solidity/contracts/converter/ConverterBase.sol

pragma solidity 0.4.26;

/**
  * @dev ConverterBase
  *
  * The converter contains the main logic for conversions between different ERC20 tokens.
  *
  * It is also the upgradable part of the mechanism (note that upgrades are opt-in).
  *
  * The anchor must be set on construction and cannot be changed afterwards.
  * Wrappers are provided for some of the anchor's functions, for easier access.
  *
  * Once the converter accepts ownership of the anchor, it becomes the anchor's sole controller
  * and can execute any of its functions.
  *
  * To upgrade the converter, anchor ownership must be transferred to a new converter, along with
  * any relevant data.
  *
  * Note that the converter can transfer anchor ownership to a new converter that
  * doesn't allow upgrades anymore, for finalizing the relationship between the converter
  * and the anchor.
  *
  * Converter types (defined as uint16 type) -
  * 0 = liquid token converter
  * 1 = liquidity pool v1 converter
  * 2 = liquidity pool v2 converter
  *
  * Note that converters don't currently support tokens with transfer fees.
*/
contract ConverterBase is IConverter, TokenHandler, TokenHolder, ContractRegistryClient, ReentrancyGuard {
    using SafeMath for uint256;

    uint32 internal constant WEIGHT_RESOLUTION = 1000000;
    uint32 internal constant CONVERSION_FEE_RESOLUTION = 1000000;
    address internal constant ETH_RESERVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    struct Reserve {
        uint256 balance;    // reserve balance
        uint32 weight;      // reserve weight, represented in ppm, 1-1000000
        bool deprecated1;   // deprecated
        bool deprecated2;   // deprecated
        bool isSet;         // true if the reserve is valid, false otherwise
    }

    /**
      * @dev version number
    */
    uint16 public constant version = 32;

    IConverterAnchor public anchor;                 // converter anchor contract
    IWhitelist public conversionWhitelist;          // whitelist contract with list of addresses that are allowed to use the converter
    IERC20Token[] public reserveTokens;             // ERC20 standard token addresses (prior version 17, use 'connectorTokens' instead)
    mapping (address => Reserve) public reserves;   // reserve token addresses -> reserve data (prior version 17, use 'connectors' instead)
    uint32 public reserveRatio = 0;                 // ratio between the reserves and the market cap, equal to the total reserve weights
    uint32 public maxConversionFee = 0;             // maximum conversion fee for the lifetime of the contract,
                                                    // represented in ppm, 0...1000000 (0 = no fee, 100 = 0.01%, 1000000 = 100%)
    uint32 public conversionFee = 0;                // current conversion fee, represented in ppm, 0...maxConversionFee
    bool public constant conversionsEnabled = true; // deprecated, backward compatibility

    /**
      * @dev triggered when the converter is activated
      *
      * @param _type        converter type
      * @param _anchor      converter anchor
      * @param _activated   true if the converter was activated, false if it was deactivated
    */
    event Activation(uint16 indexed _type, IConverterAnchor indexed _anchor, bool indexed _activated);

    /**
      * @dev triggered when a conversion between two tokens occurs
      *
      * @param _fromToken       source ERC20 token
      * @param _toToken         target ERC20 token
      * @param _trader          wallet that initiated the trade
      * @param _amount          amount converted, in the source token
      * @param _return          amount returned, minus conversion fee
      * @param _conversionFee   conversion fee
    */
    event Conversion(
        address indexed _fromToken,
        address indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

    /**
      * @dev triggered when the rate between two tokens in the converter changes
      * note that the event might be dispatched for rate updates between any two tokens in the converter
      * note that prior to version 28, you should use the 'PriceDataUpdate' event instead
      *
      * @param  _token1 address of the first token
      * @param  _token2 address of the second token
      * @param  _rateN  rate of 1 unit of `_token1` in `_token2` (numerator)
      * @param  _rateD  rate of 1 unit of `_token1` in `_token2` (denominator)
    */
    event TokenRateUpdate(
        address indexed _token1,
        address indexed _token2,
        uint256 _rateN,
        uint256 _rateD
    );

    /**
      * @dev triggered when the conversion fee is updated
      *
      * @param  _prevFee    previous fee percentage, represented in ppm
      * @param  _newFee     new fee percentage, represented in ppm
    */
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);

    /**
      * @dev used by sub-contracts to initialize a new converter
      *
      * @param  _anchor             anchor governed by the converter
      * @param  _registry           address of a contract registry contract
      * @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    constructor(
        IConverterAnchor _anchor,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        validAddress(_anchor)
        ContractRegistryClient(_registry)
        internal
        validConversionFee(_maxConversionFee)
    {
        anchor = _anchor;
        maxConversionFee = _maxConversionFee;
    }

    // ensures that the converter is active
    modifier active() {
        _active();
        _;
    }

    // error message binary size optimization
    function _active() internal view {
        require(isActive(), "ERR_INACTIVE");
    }

    // ensures that the converter is not active
    modifier inactive() {
        _inactive();
        _;
    }

    // error message binary size optimization
    function _inactive() internal view {
        require(!isActive(), "ERR_ACTIVE");
    }

    // validates a reserve token address - verifies that the address belongs to one of the reserve tokens
    modifier validReserve(IERC20Token _address) {
        _validReserve(_address);
        _;
    }

    // error message binary size optimization
    function _validReserve(IERC20Token _address) internal view {
        require(reserves[_address].isSet, "ERR_INVALID_RESERVE");
    }

    // validates conversion fee
    modifier validConversionFee(uint32 _conversionFee) {
        _validConversionFee(_conversionFee);
        _;
    }

    // error message binary size optimization
    function _validConversionFee(uint32 _conversionFee) internal pure {
        require(_conversionFee <= CONVERSION_FEE_RESOLUTION, "ERR_INVALID_CONVERSION_FEE");
    }

    // validates reserve weight
    modifier validReserveWeight(uint32 _weight) {
        _validReserveWeight(_weight);
        _;
    }

    // error message binary size optimization
    function _validReserveWeight(uint32 _weight) internal pure {
        require(_weight > 0 && _weight <= WEIGHT_RESOLUTION, "ERR_INVALID_RESERVE_WEIGHT");
    }

    /**
      * @dev deposits ether
      * can only be called if the converter has an ETH reserve
    */
    function() external payable {
        require(reserves[ETH_RESERVE_ADDRESS].isSet, "ERR_INVALID_RESERVE"); // require(hasETHReserve(), "ERR_INVALID_RESERVE");
        // a workaround for a problem when running solidity-coverage
        // see https://github.com/sc-forks/solidity-coverage/issues/487
    }

    /**
      * @dev withdraws ether
      * can only be called by the owner if the converter is inactive or by upgrader contract
      * can only be called after the upgrader contract has accepted the ownership of this contract
      * can only be called if the converter has an ETH reserve
      *
      * @param _to  address to send the ETH to
    */
    function withdrawETH(address _to)
        public
        protected
        ownerOnly
        validReserve(IERC20Token(ETH_RESERVE_ADDRESS))
    {
        address converterUpgrader = addressOf(CONVERTER_UPGRADER);

        // verify that the converter is inactive or that the owner is the upgrader contract
        require(!isActive() || owner == converterUpgrader, "ERR_ACCESS_DENIED");
        _to.transfer(address(this).balance);

        // sync the ETH reserve balance
        syncReserveBalance(IERC20Token(ETH_RESERVE_ADDRESS));
    }

    /**
      * @dev checks whether or not the converter version is 28 or higher
      *
      * @return true, since the converter version is 28 or higher
    */
    function isV28OrHigher() public pure returns (bool) {
        return true;
    }

    /**
      * @dev allows the owner to update & enable the conversion whitelist contract address
      * when set, only addresses that are whitelisted are actually allowed to use the converter
      * note that the whitelist check is actually done by the BancorNetwork contract
      *
      * @param _whitelist    address of a whitelist contract
    */
    function setConversionWhitelist(IWhitelist _whitelist)
        public
        ownerOnly
        notThis(_whitelist)
    {
        conversionWhitelist = _whitelist;
    }

    /**
      * @dev returns true if the converter is active, false otherwise
      *
      * @return true if the converter is active, false otherwise
    */
    function isActive() public view returns (bool) {
        return anchor.owner() == address(this);
    }

    /**
      * @dev transfers the anchor ownership
      * the new owner needs to accept the transfer
      * can only be called by the converter upgrder while the upgrader is the owner
      * note that prior to version 28, you should use 'transferAnchorOwnership' instead
      *
      * @param _newOwner    new token owner
    */
    function transferAnchorOwnership(address _newOwner)
        public
        ownerOnly
        only(CONVERTER_UPGRADER)
    {
        anchor.transferOwnership(_newOwner);
    }

    /**
      * @dev accepts ownership of the anchor after an ownership transfer
      * most converters are also activated as soon as they accept the anchor ownership
      * can only be called by the contract owner
      * note that prior to version 28, you should use 'acceptTokenOwnership' instead
    */
    function acceptAnchorOwnership() public ownerOnly {
        // verify the the converter has at least one reserve
        require(reserveTokenCount() > 0, "ERR_INVALID_RESERVE_COUNT");
        anchor.acceptOwnership();
        syncReserveBalances();
    }

    /**
      * @dev withdraws tokens held by the anchor and sends them to an account
      * can only be called by the owner
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawFromAnchor(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        anchor.withdrawTokens(_token, _to, _amount);
    }

    /**
      * @dev updates the current conversion fee
      * can only be called by the contract owner
      *
      * @param _conversionFee new conversion fee, represented in ppm
    */
    function setConversionFee(uint32 _conversionFee) public ownerOnly {
        require(_conversionFee <= maxConversionFee, "ERR_INVALID_CONVERSION_FEE");
        emit ConversionFeeUpdate(conversionFee, _conversionFee);
        conversionFee = _conversionFee;
    }

    /**
      * @dev withdraws tokens held by the converter and sends them to an account
      * can only be called by the owner
      * note that reserve tokens can only be withdrawn by the owner while the converter is inactive
      * unless the owner is the converter upgrader contract
      *
      * @param _token   ERC20 token contract address
      * @param _to      account to receive the new amount
      * @param _amount  amount to withdraw
    */
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public protected ownerOnly {
        address converterUpgrader = addressOf(CONVERTER_UPGRADER);

        // if the token is not a reserve token, allow withdrawal
        // otherwise verify that the converter is inactive or that the owner is the upgrader contract
        require(!reserves[_token].isSet || !isActive() || owner == converterUpgrader, "ERR_ACCESS_DENIED");
        super.withdrawTokens(_token, _to, _amount);

        // if the token is a reserve token, sync the reserve balance
        if (reserves[_token].isSet)
            syncReserveBalance(_token);
    }

    /**
      * @dev upgrades the converter to the latest version
      * can only be called by the owner
      * note that the owner needs to call acceptOwnership on the new converter after the upgrade
    */
    function upgrade() public ownerOnly {
        IConverterUpgrader converterUpgrader = IConverterUpgrader(addressOf(CONVERTER_UPGRADER));

        // trigger de-activation event
        emit Activation(converterType(), anchor, false);

        transferOwnership(converterUpgrader);
        converterUpgrader.upgrade(version);
        acceptOwnership();
    }

    /**
      * @dev returns the number of reserve tokens defined
      * note that prior to version 17, you should use 'connectorTokenCount' instead
      *
      * @return number of reserve tokens
    */
    function reserveTokenCount() public view returns (uint16) {
        return uint16(reserveTokens.length);
    }

    /**
      * @dev defines a new reserve token for the converter
      * can only be called by the owner while the converter is inactive
      *
      * @param _token   address of the reserve token
      * @param _weight  reserve weight, represented in ppm, 1-1000000
    */
    function addReserve(IERC20Token _token, uint32 _weight)
        public
        ownerOnly
        inactive
        validAddress(_token)
        notThis(_token)
        validReserveWeight(_weight)
    {
        // validate input
        require(_token != address(anchor) && !reserves[_token].isSet, "ERR_INVALID_RESERVE");
        require(_weight <= WEIGHT_RESOLUTION - reserveRatio, "ERR_INVALID_RESERVE_WEIGHT");
        require(reserveTokenCount() < uint16(-1), "ERR_INVALID_RESERVE_COUNT");

        Reserve storage newReserve = reserves[_token];
        newReserve.balance = 0;
        newReserve.weight = _weight;
        newReserve.isSet = true;
        reserveTokens.push(_token);
        reserveRatio += _weight;
    }

    /**
      * @dev returns the reserve's weight
      * added in version 28
      *
      * @param _reserveToken    reserve token contract address
      *
      * @return reserve weight
    */
    function reserveWeight(IERC20Token _reserveToken)
        public
        view
        validReserve(_reserveToken)
        returns (uint32)
    {
        return reserves[_reserveToken].weight;
    }

    /**
      * @dev returns the reserve's balance
      * note that prior to version 17, you should use 'getConnectorBalance' instead
      *
      * @param _reserveToken    reserve token contract address
      *
      * @return reserve balance
    */
    function reserveBalance(IERC20Token _reserveToken)
        public
        view
        validReserve(_reserveToken)
        returns (uint256)
    {
        return reserves[_reserveToken].balance;
    }

    /**
      * @dev checks whether or not the converter has an ETH reserve
      *
      * @return true if the converter has an ETH reserve, false otherwise
    */
    function hasETHReserve() public view returns (bool) {
        return reserves[ETH_RESERVE_ADDRESS].isSet;
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * can only be called by the bancor network contract
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function convert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, address _trader, address _beneficiary)
        public
        payable
        protected
        only(BANCOR_NETWORK)
        returns (uint256)
    {
        // validate input
        require(_sourceToken != _targetToken, "ERR_SAME_SOURCE_TARGET");

        // if a whitelist is set, verify that both and trader and the beneficiary are whitelisted
        require(conversionWhitelist == address(0) ||
                (conversionWhitelist.isWhitelisted(_trader) && conversionWhitelist.isWhitelisted(_beneficiary)),
                "ERR_NOT_WHITELISTED");

        return doConvert(_sourceToken, _targetToken, _amount, _trader, _beneficiary);
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * called by ConverterBase and allows the inherited contracts to implement custom conversion logic
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function doConvert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, address _trader, address _beneficiary) internal returns (uint256);

    /**
      * @dev returns the conversion fee for a given target amount
      *
      * @param _targetAmount  target amount
      *
      * @return conversion fee
    */
    function calculateFee(uint256 _targetAmount) internal view returns (uint256) {
        return _targetAmount.mul(conversionFee).div(CONVERSION_FEE_RESOLUTION);
    }

    /**
      * @dev syncs the stored reserve balance for a given reserve with the real reserve balance
      *
      * @param _reserveToken    address of the reserve token
    */
    function syncReserveBalance(IERC20Token _reserveToken) internal validReserve(_reserveToken) {
        if (_reserveToken == ETH_RESERVE_ADDRESS)
            reserves[_reserveToken].balance = address(this).balance;
        else
            reserves[_reserveToken].balance = _reserveToken.balanceOf(this);
    }

    /**
      * @dev syncs all stored reserve balances
    */
    function syncReserveBalances() internal {
        uint256 reserveCount = reserveTokens.length;
        for (uint256 i = 0; i < reserveCount; i++)
            syncReserveBalance(reserveTokens[i]);
    }

    /**
      * @dev helper, dispatches the Conversion event
      *
      * @param _sourceToken     source ERC20 token
      * @param _targetToken     target ERC20 token
      * @param _trader          address of the caller who executed the conversion
      * @param _amount          amount purchased/sold (in the source token)
      * @param _returnAmount    amount returned (in the target token)
    */
    function dispatchConversionEvent(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        address _trader,
        uint256 _amount,
        uint256 _returnAmount,
        uint256 _feeAmount)
        internal
    {
        // fee amount is converted to 255 bits -
        // negative amount means the fee is taken from the source token, positive amount means its taken from the target token
        // currently the fee is always taken from the target token
        // since we convert it to a signed number, we first ensure that it's capped at 255 bits to prevent overflow
        assert(_feeAmount < 2 ** 255);
        emit Conversion(_sourceToken, _targetToken, _trader, _amount, _returnAmount, int256(_feeAmount));
    }

    /**
      * @dev deprecated since version 28, backward compatibility - use only for earlier versions
    */
    function token() public view returns (IConverterAnchor) {
        return anchor;
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function transferTokenOwnership(address _newOwner) public ownerOnly {
        transferAnchorOwnership(_newOwner);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function acceptTokenOwnership() public ownerOnly {
        acceptAnchorOwnership();
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool) {
        Reserve memory reserve = reserves[_address];
        return(reserve.balance, reserve.weight, false, false, reserve.isSet);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectorTokens(uint256 _index) public view returns (IERC20Token) {
        return ConverterBase.reserveTokens[_index];
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function connectorTokenCount() public view returns (uint16) {
        return reserveTokenCount();
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256) {
        return reserveBalance(_connectorToken);
    }

    /**
      * @dev deprecated, backward compatibility
    */
    function getReturn(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) public view returns (uint256, uint256) {
        return targetAmountAndFee(_sourceToken, _targetToken, _amount);
    }
}

// File: solidity/contracts/converter/LiquidityPoolConverter.sol

pragma solidity 0.4.26;

/**
  * @dev Liquidity Pool Converter
  *
  * The liquidity pool converter is the base contract for specific types of converters that
  * manage liquidity pools.
  *
  * Liquidity pools have 2 reserves or more and they allow converting between them.
  *
  * Note that TokenRateUpdate events are dispatched for pool tokens as well.
  * The pool token is the first token in the event in that case.
*/
contract LiquidityPoolConverter is ConverterBase {
    /**
      * @dev triggered after liquidity is added
      *
      * @param  _provider       liquidity provider
      * @param  _reserveToken   reserve token address
      * @param  _amount         reserve token amount
      * @param  _newBalance     reserve token new balance
      * @param  _newSupply      pool token new supply
    */
    event LiquidityAdded(
        address indexed _provider,
        address indexed _reserveToken,
        uint256 _amount,
        uint256 _newBalance,
        uint256 _newSupply
    );

    /**
      * @dev triggered after liquidity is removed
      *
      * @param  _provider       liquidity provider
      * @param  _reserveToken   reserve token address
      * @param  _amount         reserve token amount
      * @param  _newBalance     reserve token new balance
      * @param  _newSupply      pool token new supply
    */
    event LiquidityRemoved(
        address indexed _provider,
        address indexed _reserveToken,
        uint256 _amount,
        uint256 _newBalance,
        uint256 _newSupply
    );

    /**
      * @dev initializes a new LiquidityPoolConverter instance
      *
      * @param  _anchor             anchor governed by the converter
      * @param  _registry           address of a contract registry contract
      * @param  _maxConversionFee   maximum conversion fee, represented in ppm
    */
    constructor(
        IConverterAnchor _anchor,
        IContractRegistry _registry,
        uint32 _maxConversionFee
    )
        ConverterBase(_anchor, _registry, _maxConversionFee)
        internal
    {
    }

    /**
      * @dev accepts ownership of the anchor after an ownership transfer
      * also activates the converter
      * can only be called by the contract owner
      * note that prior to version 28, you should use 'acceptTokenOwnership' instead
    */
    function acceptAnchorOwnership() public {
        // verify that the converter has at least 2 reserves
        require(reserveTokenCount() > 1, "ERR_INVALID_RESERVE_COUNT");
        super.acceptAnchorOwnership();
    }
}

// File: solidity/contracts/converter/interfaces/IConverterFactory.sol

pragma solidity 0.4.26;





/*
    Converter Factory interface
*/
contract IConverterFactory {
    function createAnchor(uint16 _type, string _name, string _symbol, uint8 _decimals) public returns (IConverterAnchor);
    function createConverter(uint16 _type, IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee) public returns (IConverter);

    function customFactories(uint16 _type) public view returns (ITypedConverterCustomFactory) { _type; this; }
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/LiquidityPoolV2Converter.sol

pragma solidity 0.4.26;

/**
  * @dev Liquidity Pool v2 Converter
  *
  * The liquidity pool v2 converter is a specialized version of a converter that uses
  * price oracles to rebalance the reserve weights in such a way that the primary token
  * balance always strives to match the staked balance.
  *
  * This type of liquidity pool always has 2 reserves and the reserve weights are dynamic.
*/
contract LiquidityPoolV2Converter is LiquidityPoolConverter {
    uint8 internal constant AMPLIFICATION_FACTOR = 20;  // factor to use for conversion calculations (reduces slippage)
    uint32 internal constant MAX_DYNAMIC_FEE_FACTOR = 100000; // maximum dynamic-fee factor; must be <= CONVERSION_FEE_RESOLUTION

    struct Fraction {
        uint256 n;  // numerator
        uint256 d;  // denominator
    }

    IPriceOracle public priceOracle;                                // external price oracle
    IERC20Token public primaryReserveToken;                         // primary reserve in the pool
    IERC20Token public secondaryReserveToken;                       // secondary reserve in the pool (cache)
    mapping (address => uint256) private stakedBalances;            // tracks the staked liquidity in the pool plus the fees
    mapping (address => ISmartToken) private reservesToPoolTokens;  // maps each reserve to its pool token
    mapping (address => IERC20Token) private poolTokensToReserves;  // maps each pool token to its reserve

    // the period of time it takes to the last rate to fully take effect
    uint256 private constant RATE_PROPAGATION_PERIOD = 10 minutes;

    Fraction public referenceRate;              // reference rate from the previous block(s) of 1 primary token in secondary tokens
    uint256 public referenceRateUpdateTime;     // last time when the reference rate was updated (in seconds)

    Fraction public lastConversionRate;         // last conversion rate of 1 primary token in secondary tokens

    // used by the temp liquidity limit mechanism during the pilot
    mapping (address => uint256) public maxStakedBalances;
    bool public maxStakedBalanceEnabled = true;

    uint256 public dynamicFeeFactor = 70000; // initial dynamic fee factor is 7%, represented in ppm

    /**
      * @dev triggered when the dynamic fee factor is updated
      *
      * @param  _prevFactor    previous factor percentage, represented in ppm
      * @param  _newFactor     new factor percentage, represented in ppm
    */
    event DynamicFeeFactorUpdate(uint256 _prevFactor, uint256 _newFactor);

    /**
      * @dev initializes a new LiquidityPoolV2Converter instance
      *
      * @param  _poolTokensContainer    pool tokens container governed by the converter
      * @param  _registry               address of a contract registry contract
      * @param  _maxConversionFee       maximum conversion fee, represented in ppm
    */
    constructor(IPoolTokensContainer _poolTokensContainer, IContractRegistry _registry, uint32 _maxConversionFee)
        public LiquidityPoolConverter(_poolTokensContainer, _registry, _maxConversionFee)
    {
    }

    // ensures the address is a pool token
    modifier validPoolToken(ISmartToken _address) {
        _validPoolToken(_address);
        _;
    }

    // error message binary size optimization
    function _validPoolToken(ISmartToken _address) internal view {
        require(poolTokensToReserves[_address] != address(0), "ERR_INVALID_POOL_TOKEN");
    }

    /**
      * @dev returns the converter type
      *
      * @return see the converter types in the the main contract doc
    */
    function converterType() public pure returns (uint16) {
        return 2;
    }

    /**
      * @dev returns true if the converter is active, false otherwise
      *
      * @return true if the converter is active, false otherwise
    */
    function isActive() public view returns (bool) {
        return super.isActive() && priceOracle != address(0);
    }

    /**
      * @dev returns the liquidity amplification factor in the pool
      *
      * @return liquidity amplification factor
    */
    function amplificationFactor() public pure returns (uint8) {
        return AMPLIFICATION_FACTOR;
    }

    /**
      * @dev sets the pool's primary reserve token / price oracles and activates the pool
      * each oracle must be able to provide the rate for each reserve token
      * note that the oracle must be whitelisted prior to the call
      * can only be called by the owner while the pool is inactive
      *
      * @param _primaryReserveToken     address of the pool's primary reserve token
      * @param _primaryReserveOracle    address of a chainlink price oracle for the primary reserve token
      * @param _secondaryReserveOracle  address of a chainlink price oracle for the secondary reserve token
    */
    function activate(IERC20Token _primaryReserveToken, IChainlinkPriceOracle _primaryReserveOracle, IChainlinkPriceOracle _secondaryReserveOracle)
        public
        inactive
        ownerOnly
        validReserve(_primaryReserveToken)
        notThis(_primaryReserveOracle)
        notThis(_secondaryReserveOracle)
        validAddress(_primaryReserveOracle)
        validAddress(_secondaryReserveOracle)
    {
        // validate anchor ownership
        require(anchor.owner() == address(this), "ERR_ANCHOR_NOT_OWNED");

        // validate oracles
        IWhitelist oracleWhitelist = IWhitelist(addressOf(CHAINLINK_ORACLE_WHITELIST));
        require(oracleWhitelist.isWhitelisted(_primaryReserveOracle), "ERR_INVALID_ORACLE");
        require(oracleWhitelist.isWhitelisted(_secondaryReserveOracle), "ERR_INVALID_ORACLE");

        // create the converter's pool tokens if they don't already exist
        createPoolTokens();

        // sets the primary & secondary reserve tokens
        primaryReserveToken = _primaryReserveToken;
        if (_primaryReserveToken == reserveTokens[0])
            secondaryReserveToken = reserveTokens[1];
        else
            secondaryReserveToken = reserveTokens[0];

        // creates and initalizes the price oracle and sets initial rates
        LiquidityPoolV2ConverterCustomFactory customFactory =
            LiquidityPoolV2ConverterCustomFactory(IConverterFactory(addressOf(CONVERTER_FACTORY)).customFactories(converterType()));
        priceOracle = customFactory.createPriceOracle(_primaryReserveToken, secondaryReserveToken, _primaryReserveOracle, _secondaryReserveOracle);

        (referenceRate.n, referenceRate.d) = priceOracle.latestRate(primaryReserveToken, secondaryReserveToken);
        lastConversionRate = referenceRate;

        referenceRateUpdateTime = time();

        // if we are upgrading from an older converter, make sure that reserve balances are in-sync and rebalance
        uint256 primaryReserveStakedBalance = reserveStakedBalance(primaryReserveToken);
        uint256 primaryReserveBalance = reserveBalance(primaryReserveToken);
        uint256 secondaryReserveBalance = reserveBalance(secondaryReserveToken);

        if (primaryReserveStakedBalance == primaryReserveBalance) {
            if (primaryReserveStakedBalance > 0 || secondaryReserveBalance > 0) {
                rebalance();
            }
        }
        else if (primaryReserveStakedBalance > 0 && primaryReserveBalance > 0 && secondaryReserveBalance > 0) {
            rebalance();
        }

        emit Activation(converterType(), anchor, true);
    }

    /**
      * @dev updates the current dynamic fee factor
      * can only be called by the contract owner
      *
      * @param _dynamicFeeFactor new dynamic fee factor, represented in ppm
    */
    function setDynamicFeeFactor(uint256 _dynamicFeeFactor) public ownerOnly {
        require(_dynamicFeeFactor <= MAX_DYNAMIC_FEE_FACTOR, "ERR_INVALID_DYNAMIC_FEE_FACTOR");
        emit DynamicFeeFactorUpdate(dynamicFeeFactor, _dynamicFeeFactor);
        dynamicFeeFactor = _dynamicFeeFactor;
    }

    /**
      * @dev returns the staked balance of a given reserve token
      *
      * @param _reserveToken    reserve token address
      *
      * @return staked balance
    */
    function reserveStakedBalance(IERC20Token _reserveToken)
        public
        view
        validReserve(_reserveToken)
        returns (uint256)
    {
        return stakedBalances[_reserveToken];
    }

    /**
      * @dev returns the amplified balance of a given reserve token
      *
      * @param _reserveToken   reserve token address
      *
      * @return amplified balance
    */
    function reserveAmplifiedBalance(IERC20Token _reserveToken)
        public
        view
        validReserve(_reserveToken)
        returns (uint256)
    {
        return stakedBalances[_reserveToken].mul(AMPLIFICATION_FACTOR - 1).add(reserveBalance(_reserveToken));
    }

    /**
      * @dev sets the reserve's staked balance
      * can only be called by the upgrader contract while the upgrader is the owner
      *
      * @param _reserveToken    reserve token address
      * @param _balance         new reserve staked balance
    */
    function setReserveStakedBalance(IERC20Token _reserveToken, uint256 _balance)
        public
        ownerOnly
        only(CONVERTER_UPGRADER)
        validReserve(_reserveToken)
    {
        stakedBalances[_reserveToken] = _balance;
    }

    /**
      * @dev sets the max staked balance for both reserves
      * available as a temporary mechanism during the pilot
      * can only be called by the owner
      *
      * @param _reserve1MaxStakedBalance    max staked balance for reserve 1
      * @param _reserve2MaxStakedBalance    max staked balance for reserve 2
    */
    function setMaxStakedBalances(uint256 _reserve1MaxStakedBalance, uint256 _reserve2MaxStakedBalance) public ownerOnly {
        maxStakedBalances[reserveTokens[0]] = _reserve1MaxStakedBalance;
        maxStakedBalances[reserveTokens[1]] = _reserve2MaxStakedBalance;
    }

    /**
      * @dev disables the max staked balance mechanism
      * available as a temporary mechanism during the pilot
      * once disabled, it cannot be re-enabled
      * can only be called by the owner
    */
    function disableMaxStakedBalances() public ownerOnly {
        maxStakedBalanceEnabled = false;
    }

    /**
      * @dev returns the pool token address by the reserve token address
      *
      * @param _reserveToken    reserve token address
      *
      * @return pool token address
    */
    function poolToken(IERC20Token _reserveToken) public view returns (ISmartToken) {
        return reservesToPoolTokens[_reserveToken];
    }

    /**
      * @dev returns the maximum number of pool tokens that can currently be liquidated
      *
      * @param _poolToken   address of the pool token
      *
      * @return liquidation limit
    */
    function liquidationLimit(ISmartToken _poolToken) public view returns (uint256) {
        // get the pool token supply
        uint256 poolTokenSupply = _poolToken.totalSupply();

        // get the reserve token associated with the pool token and its balance / staked balance
        IERC20Token reserveToken = poolTokensToReserves[_poolToken];
        uint256 balance = reserveBalance(reserveToken);
        uint256 stakedBalance = stakedBalances[reserveToken];

        // calculate the amount that's available for liquidation
        return balance.mul(poolTokenSupply).div(stakedBalance);
    }

    /**
      * @dev defines a new reserve token for the converter
      * can only be called by the owner while the converter is inactive and
      * 2 reserves aren't defined yet
      *
      * @param _token   address of the reserve token
      * @param _weight  reserve weight, represented in ppm, 1-1000000
    */
    function addReserve(IERC20Token _token, uint32 _weight) public {
        // verify that the converter doesn't have 2 reserves yet
        require(reserveTokenCount() < 2, "ERR_INVALID_RESERVE_COUNT");
        super.addReserve(_token, _weight);
    }

    /**
      * @dev returns the effective rate of 1 primary token in secondary tokens
      *
      * @return rate of 1 primary token in secondary tokens (numerator)
      * @return rate of 1 primary token in secondary tokens (denominator)
    */
    function effectiveTokensRate() public view returns (uint256, uint256) {
        Fraction memory rate = _effectiveTokensRate();
        return (rate.n, rate.d);
    }

    /**
      * @dev returns the effective reserve tokens weights
      *
      * @return reserve1 weight
      * @return reserve2 weight
    */
    function effectiveReserveWeights() public view returns (uint256, uint256) {
        Fraction memory rate = _effectiveTokensRate();
        (uint32 primaryReserveWeight, uint32 secondaryReserveWeight) = effectiveReserveWeights(rate);

        if (primaryReserveToken == reserveTokens[0]) {
            return (primaryReserveWeight, secondaryReserveWeight);
        }

        return (secondaryReserveWeight, primaryReserveWeight);
    }

    /**
      * @dev returns the expected target amount of converting one reserve to another along with the fee
      *
      * @param _sourceToken contract address of the source reserve token
      * @param _targetToken contract address of the target reserve token
      * @param _amount      amount of tokens received from the user
      *
      * @return expected target amount
      * @return expected fee
    */
    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount)
        public
        view
        active
        returns (uint256, uint256)
    {
        // validate input
        // not using the `validReserve` modifier to circumvent `stack too deep` compiler error
        _validReserve(_sourceToken);
        _validReserve(_targetToken);
        require(_sourceToken != _targetToken, "ERR_SAME_SOURCE_TARGET");

        // check if rebalance is required (some of this code is duplicated for gas optimization)
        uint32 sourceTokenWeight;
        uint32 targetTokenWeight;

        // if the rate was already checked in this block, use the current weights.
        // otherwise, get the new weights
        Fraction memory rate;
        if (referenceRateUpdateTime == time()) {
            rate = referenceRate;
            sourceTokenWeight = reserves[_sourceToken].weight;
            targetTokenWeight = reserves[_targetToken].weight;
        }
        else {
            // get the new rate / reserve weights
            rate = _effectiveTokensRate();
            (uint32 primaryReserveWeight, uint32 secondaryReserveWeight) = effectiveReserveWeights(rate);

            if (_sourceToken == primaryReserveToken) {
                sourceTokenWeight = primaryReserveWeight;
                targetTokenWeight = secondaryReserveWeight;
            }
            else {
                sourceTokenWeight = secondaryReserveWeight;
                targetTokenWeight = primaryReserveWeight;
            }
        }

        // return the target amount and the conversion fee using the updated reserve weights
        (uint256 targetAmount, , uint256 fee) = targetAmountAndFees(_sourceToken, _targetToken, sourceTokenWeight, targetTokenWeight, rate, _amount);
        return (targetAmount, fee);
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * can only be called by the bancor network contract
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      * @param _trader      address of the caller who executed the conversion
      * @param _beneficiary wallet to receive the conversion result
      *
      * @return amount of tokens received (in units of the target token)
    */
    function doConvert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount, address _trader, address _beneficiary)
        internal
        active
        validReserve(_sourceToken)
        validReserve(_targetToken)
        returns (uint256)
    {
        // convert the amount and return the resulted amount and fee
        (uint256 amount, uint256 fee) = doConvert(_sourceToken, _targetToken, _amount);

        // transfer funds to the beneficiary in the to reserve token
        if (_targetToken == ETH_RESERVE_ADDRESS) {
            _beneficiary.transfer(amount);
        }
        else {
            safeTransfer(_targetToken, _beneficiary, amount);
        }

        // dispatch the conversion event
        dispatchConversionEvent(_sourceToken, _targetToken, _trader, _amount, amount, fee);

        // dispatch rate updates for the pool / reserve tokens
        dispatchRateEvents(_sourceToken, _targetToken, reserves[_sourceToken].weight, reserves[_targetToken].weight);

        // return the conversion result amount
        return amount;
    }

    /**
      * @dev converts a specific amount of source tokens to target tokens
      * can only be called by the bancor network contract
      *
      * @param _sourceToken source ERC20 token
      * @param _targetToken target ERC20 token
      * @param _amount      amount of tokens to convert (in units of the source token)
      *
      * @return amount of tokens received (in units of the target token)
      * @return expected fee
    */
    function doConvert(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) private returns (uint256, uint256) {
        // check if the rate has changed and rebalance the pool if needed (once in a block)
        (bool rateUpdated, Fraction memory rate) = handleRateChange();

        // get expected target amount and fees
        (uint256 amount, uint256 standardFee, uint256 dynamicFee) = targetAmountAndFees(_sourceToken, _targetToken, 0, 0, rate, _amount);

        // ensure that the trade gives something in return
        require(amount != 0, "ERR_ZERO_TARGET_AMOUNT");

        // ensure that the trade won't deplete the reserve balance
        uint256 targetReserveBalance = reserveBalance(_targetToken);
        require(amount < targetReserveBalance, "ERR_TARGET_AMOUNT_TOO_HIGH");

        // ensure that the input amount was already deposited
        if (_sourceToken == ETH_RESERVE_ADDRESS)
            require(msg.value == _amount, "ERR_ETH_AMOUNT_MISMATCH");
        else
            require(msg.value == 0 && _sourceToken.balanceOf(this).sub(reserveBalance(_sourceToken)) >= _amount, "ERR_INVALID_AMOUNT");

        // sync the reserve balances
        syncReserveBalance(_sourceToken);
        reserves[_targetToken].balance = targetReserveBalance.sub(amount);

        // update the target staked balance with the fee
        stakedBalances[_targetToken] = stakedBalances[_targetToken].add(standardFee);

        // update the last conversion rate
        if (rateUpdated) {
            lastConversionRate = tokensRate(primaryReserveToken, secondaryReserveToken, 0, 0);
        }

        return (amount, dynamicFee);
    }

    /**
      * @dev increases the pool's liquidity and mints new shares in the pool to the caller
      *
      * @param _reserveToken    address of the reserve token to add liquidity to
      * @param _amount          amount of liquidity to add
      * @param _minReturn       minimum return-amount of pool tokens
      *
      * @return amount of pool tokens minted
    */
    function addLiquidity(IERC20Token _reserveToken, uint256 _amount, uint256 _minReturn)
        public
        payable
        protected
        active
        validReserve(_reserveToken)
        greaterThanZero(_amount)
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        // verify that msg.value is identical to the provided amount for ETH reserve, or 0 otherwise
        require(_reserveToken == ETH_RESERVE_ADDRESS ? msg.value == _amount : msg.value == 0, "ERR_ETH_AMOUNT_MISMATCH");

        // sync the reserve balances just in case
        syncReserveBalances();

        // for ETH reserve, deduct the amount that was just synced (since it's already in the converter)
        if (_reserveToken == ETH_RESERVE_ADDRESS)
            reserves[ETH_RESERVE_ADDRESS].balance = reserves[ETH_RESERVE_ADDRESS].balance.sub(msg.value);

        // get the reserve staked balance before adding the liquidity to it
        uint256 initialStakedBalance = stakedBalances[_reserveToken];

        // during the pilot, ensure that the new staked balance isn't greater than the max limit
        if (maxStakedBalanceEnabled) {
            require(maxStakedBalances[_reserveToken] == 0 || initialStakedBalance.add(_amount) <= maxStakedBalances[_reserveToken], "ERR_MAX_STAKED_BALANCE_REACHED");
        }

        // get the pool token associated with the reserve and its supply
        ISmartToken reservePoolToken = reservesToPoolTokens[_reserveToken];
        uint256 poolTokenSupply = reservePoolToken.totalSupply();

        // for non ETH reserve, transfer the funds from the user to the pool
        if (_reserveToken != ETH_RESERVE_ADDRESS)
            safeTransferFrom(_reserveToken, msg.sender, this, _amount);

        // sync the reserve balance / staked balance
        reserves[_reserveToken].balance = reserves[_reserveToken].balance.add(_amount);
        stakedBalances[_reserveToken] = initialStakedBalance.add(_amount);

        // calculate how many pool tokens to mint
        // for an empty pool, the price is 1:1, otherwise the price is based on the ratio
        // between the pool token supply and the staked balance
        uint256 poolTokenAmount = 0;
        if (initialStakedBalance == 0 || poolTokenSupply == 0)
            poolTokenAmount = _amount;
        else
            poolTokenAmount = _amount.mul(poolTokenSupply).div(initialStakedBalance);
        require(poolTokenAmount >= _minReturn, "ERR_RETURN_TOO_LOW");

        // mint new pool tokens to the caller
        IPoolTokensContainer(anchor).mint(reservePoolToken, msg.sender, poolTokenAmount);

        // rebalance the pool's reserve weights
        rebalance();

        // dispatch the LiquidityAdded event
        emit LiquidityAdded(msg.sender, _reserveToken, _amount, initialStakedBalance.add(_amount), poolTokenSupply.add(poolTokenAmount));

        // dispatch the `TokenRateUpdate` event for the pool token
        dispatchPoolTokenRateUpdateEvent(reservePoolToken, poolTokenSupply.add(poolTokenAmount), _reserveToken);

        // dispatch the `TokenRateUpdate` event for the reserve tokens
        dispatchTokenRateUpdateEvent(reserveTokens[0], reserveTokens[1], 0, 0);

        // return the amount of pool tokens minted
        return poolTokenAmount;
    }

    /**
      * @dev decreases the pool's liquidity and burns the caller's shares in the pool
      *
      * @param _poolToken   address of the pool token
      * @param _amount      amount of pool tokens to burn
      * @param _minReturn   minimum return-amount of reserve tokens
      *
      * @return amount of liquidity removed
    */
    function removeLiquidity(ISmartToken _poolToken, uint256 _amount, uint256 _minReturn)
        public
        protected
        active
        validPoolToken(_poolToken)
        greaterThanZero(_amount)
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        // sync the reserve balances just in case
        syncReserveBalances();

        // get the pool token supply before burning the caller's shares
        uint256 initialPoolSupply = _poolToken.totalSupply();

        // get the reserve token return before burning the caller's shares
        (uint256 reserveAmount, ) = removeLiquidityReturnAndFee(_poolToken, _amount);
        require(reserveAmount >= _minReturn, "ERR_RETURN_TOO_LOW");

        // get the reserve token associated with the pool token
        IERC20Token reserveToken = poolTokensToReserves[_poolToken];

        // burn the caller's pool tokens
        IPoolTokensContainer(anchor).burn(_poolToken, msg.sender, _amount);

        // sync the reserve balance / staked balance
        reserves[reserveToken].balance = reserves[reserveToken].balance.sub(reserveAmount);
        uint256 newStakedBalance = stakedBalances[reserveToken].sub(reserveAmount);
        stakedBalances[reserveToken] = newStakedBalance;

        // transfer the reserve amount to the caller
        if (reserveToken == ETH_RESERVE_ADDRESS)
            msg.sender.transfer(reserveAmount);
        else
            safeTransfer(reserveToken, msg.sender, reserveAmount);

        // rebalance the pool's reserve weights
        rebalance();

        uint256 newPoolTokenSupply = initialPoolSupply.sub(_amount);

        // dispatch the LiquidityRemoved event
        emit LiquidityRemoved(msg.sender, reserveToken, reserveAmount, newStakedBalance, newPoolTokenSupply);

        // dispatch the `TokenRateUpdate` event for the pool token
        dispatchPoolTokenRateUpdateEvent(_poolToken, newPoolTokenSupply, reserveToken);

        // dispatch the `TokenRateUpdate` event for the reserve tokens
        dispatchTokenRateUpdateEvent(reserveTokens[0], reserveTokens[1], 0, 0);

        // return the amount of liquidity removed
        return reserveAmount;
    }

    /**
      * @dev calculates the amount of reserve tokens entitled for a given amount of pool tokens
      * note that a fee is applied according to the equilibrium level of the primary reserve token
      *
      * @param _poolToken   address of the pool token
      * @param _amount      amount of pool tokens
      *
      * @return amount after fee and fee, in reserve token units
    */
    function removeLiquidityReturnAndFee(ISmartToken _poolToken, uint256 _amount)
        public
        view
        returns (uint256, uint256)
    {
        uint256 totalSupply = _poolToken.totalSupply();
        uint256 stakedBalance = stakedBalances[poolTokensToReserves[_poolToken]];

        if (_amount < totalSupply) {
            uint256 x = stakedBalances[primaryReserveToken].mul(AMPLIFICATION_FACTOR);
            uint256 y = reserveAmplifiedBalance(primaryReserveToken);
            (uint256 min, uint256 max) = x < y ? (x, y) : (y, x);
            uint256 amountBeforeFee = _amount.mul(stakedBalance).div(totalSupply);
            uint256 amountAfterFee = amountBeforeFee.mul(min).div(max);
            return (amountAfterFee, amountBeforeFee - amountAfterFee);
        }
        return (stakedBalance, 0);
    }

    /**
      * @dev returns the expected target amount of converting one reserve to another along with the fees
      * this version of the function expects the reserve weights as an input (gas optimization)
      *
      * @param _sourceToken     contract address of the source reserve token
      * @param _targetToken     contract address of the target reserve token
      * @param _sourceWeight    source reserve token weight or 0 to read it from storage
      * @param _targetWeight    target reserve token weight or 0 to read it from storage
      * @param _rate            rate between the reserve tokens
      * @param _amount          amount of tokens received from the user
      *
      * @return expected target amount
      * @return expected standard conversion fee
      * @return expected dynamic conversion fee
    */
    function targetAmountAndFees(
        IERC20Token _sourceToken,
        IERC20Token _targetToken,
        uint32 _sourceWeight,
        uint32 _targetWeight,
        Fraction memory _rate,
        uint256 _amount)
        private
        view
        returns (uint256 targetAmount, uint256 standardFee, uint256 dynamicFee)
    {
        if (_sourceWeight == 0)
            _sourceWeight = reserves[_sourceToken].weight;
        if (_targetWeight == 0)
            _targetWeight = reserves[_targetToken].weight;

        // get the tokens amplified balances
        uint256 sourceBalance = reserveAmplifiedBalance(_sourceToken);
        uint256 targetBalance = reserveAmplifiedBalance(_targetToken);

        // get the target amount
        targetAmount = IBancorFormula(addressOf(BANCOR_FORMULA)).crossReserveTargetAmount(
            sourceBalance,
            _sourceWeight,
            targetBalance,
            _targetWeight,
            _amount
        );

        // return a tuple of [target amount minus dynamic conversion fee, standard conversion fee, dynamic conversion fee]
        standardFee = calculateFee(targetAmount);
        dynamicFee = calculateDynamicFee(_targetToken, _sourceWeight, _targetWeight, _rate, targetAmount).add(standardFee);
        targetAmount = targetAmount.sub(dynamicFee);
    }

    /**
      * @dev returns the dynamic fee for a given target amount
      *
      * @param _targetToken     contract address of the target reserve token
      * @param _sourceWeight    source reserve token weight
      * @param _targetWeight    target reserve token weight
      * @param _rate            rate of 1 primary token in secondary tokens
      * @param _targetAmount    target amount
      *
      * @return dynamic fee
    */
    function calculateDynamicFee(
        IERC20Token _targetToken,
        uint32 _sourceWeight,
        uint32 _targetWeight,
        Fraction memory _rate,
        uint256 _targetAmount)
        internal view returns (uint256)
    {
        uint256 fee;

        if (_targetToken == secondaryReserveToken) {
            fee = calculateFeeToEquilibrium(
                stakedBalances[primaryReserveToken],
                stakedBalances[secondaryReserveToken],
                _sourceWeight,
                _targetWeight,
                _rate.n,
                _rate.d,
                dynamicFeeFactor);
        }
        else {
            fee = calculateFeeToEquilibrium(
                stakedBalances[primaryReserveToken],
                stakedBalances[secondaryReserveToken],
                _targetWeight,
                _sourceWeight,
                _rate.n,
                _rate.d,
                dynamicFeeFactor);
        }

        return _targetAmount.mul(fee).div(CONVERSION_FEE_RESOLUTION);
    }

    /**
      * @dev returns the relative fee required for mitigating the secondary reserve distance from equilibrium
      *
      * @param _primaryReserveStaked    primary reserve staked balance
      * @param _secondaryReserveStaked  secondary reserve staked balance
      * @param _primaryReserveWeight    primary reserve weight
      * @param _secondaryReserveWeight  secondary reserve weight
      * @param _primaryReserveRate      primary reserve rate
      * @param _secondaryReserveRate    secondary reserve rate
      * @param _dynamicFeeFactor        dynamic fee factor
      *
      * @return relative fee, represented in ppm
    */
    function calculateFeeToEquilibrium(
        uint256 _primaryReserveStaked,
        uint256 _secondaryReserveStaked,
        uint256 _primaryReserveWeight,
        uint256 _secondaryReserveWeight,
        uint256 _primaryReserveRate,
        uint256 _secondaryReserveRate,
        uint256 _dynamicFeeFactor)
        internal
        pure
        returns (uint256)
    {
        uint256 x = _primaryReserveStaked.mul(_primaryReserveRate).mul(_secondaryReserveWeight);
        uint256 y = _secondaryReserveStaked.mul(_secondaryReserveRate).mul(_primaryReserveWeight);
        if (y > x)
            return (y - x).mul(_dynamicFeeFactor).mul(AMPLIFICATION_FACTOR).div(y);
        return 0;
    }

    /**
      * @dev creates the converter's pool tokens
      * note that technically pool tokens can be created on deployment but gas limit
      * might get too high for a block, so creating them on first activation
      *
    */
    function createPoolTokens() internal {
        IPoolTokensContainer container = IPoolTokensContainer(anchor);
        ISmartToken[] memory poolTokens = container.poolTokens();
        bool initialSetup = poolTokens.length == 0;

        uint256 reserveCount = reserveTokens.length;
        for (uint256 i = 0; i < reserveCount; i++) {
            ISmartToken reservePoolToken;
            if (initialSetup) {
                reservePoolToken = container.createToken();
            }
            else {
                reservePoolToken = poolTokens[i];
            }

            // cache the pool token address (gas optimization)
            reservesToPoolTokens[reserveTokens[i]] = reservePoolToken;
            poolTokensToReserves[reservePoolToken] = reserveTokens[i];
        }
    }

    /**
      * @dev returns the effective rate between the two reserve tokens
      *
      * @return rate
    */
    function _effectiveTokensRate() private view returns (Fraction memory) {
        // get the external rate between the reserves
        (uint256 externalRateN, uint256 externalRateD, uint256 updateTime) = priceOracle.latestRateAndUpdateTime(primaryReserveToken, secondaryReserveToken);

        // if the external rate was recently updated - prefer it over the internal rate
        if (updateTime > referenceRateUpdateTime) {
            return Fraction({ n: externalRateN, d: externalRateD });
        }

        // get the elapsed time between the current and the last conversion
        uint256 timeElapsed = time() - referenceRateUpdateTime;

        // if both of the conversions are in the same block - use the reference rate
        if (timeElapsed == 0) {
            return referenceRate;
        }

        // given N as the sampling window, the new internal rate is calculated according to the following formula:
        //   newRate = referenceRate + timeElapsed * [lastConversionRate - referenceRate] / N

        // if a long period of time, since the last update, has passed - the last rate should fully take effect
        if (timeElapsed >= RATE_PROPAGATION_PERIOD) {
            return lastConversionRate;
        }

        // calculate the numerator and the denumerator of the new rate
        Fraction memory ref = referenceRate;
        Fraction memory last = lastConversionRate;

        uint256 x = ref.d.mul(last.n);
        uint256 y = ref.n.mul(last.d);

        // since we know that timeElapsed < RATE_PROPAGATION_PERIOD, we can avoid using SafeMath:
        uint256 newRateN = y.mul(RATE_PROPAGATION_PERIOD - timeElapsed).add(x.mul(timeElapsed));
        uint256 newRateD = ref.d.mul(last.d).mul(RATE_PROPAGATION_PERIOD);

        return reduceRate(newRateN, newRateD);
    }

    /**
      * @dev checks if the rate has changed and if so, rebalances the weights
      * note that rebalancing based on rate change only happens once per block
      *
      * @return whether the rate was updated
      * @return rate between the reserve tokens
    */
    function handleRateChange() private returns (bool, Fraction memory) {
        uint256 currentTime = time();

        // avoid updating the rate more than once per block
        if (referenceRateUpdateTime == currentTime) {
            return (false, referenceRate);
        }

        // get and store the effective rate between the reserves
        Fraction memory newRate = _effectiveTokensRate();

        // if the rate has changed, update it and rebalance the pool
        Fraction memory ref = referenceRate;
        if (newRate.n == ref.n && newRate.d == ref.d) {
            return (false, newRate);
        }

        referenceRate = newRate;
        referenceRateUpdateTime = currentTime;

        rebalance();

        return (true, newRate);
    }

    /**
      * @dev updates the pool's reserve weights with new values in order to push the current primary
      * reserve token balance to its staked balance
    */
    function rebalance() private {
        // get the new reserve weights
        (uint32 primaryReserveWeight, uint32 secondaryReserveWeight) = effectiveReserveWeights(referenceRate);

        // update the reserve weights with the new values
        reserves[primaryReserveToken].weight = primaryReserveWeight;
        reserves[secondaryReserveToken].weight = secondaryReserveWeight;
    }

    /**
      * @dev returns the effective reserve weights based on the staked balance, current balance and oracle price
      *
      * @param _rate    rate between the reserve tokens
      *
      * @return new primary reserve weight
      * @return new secondary reserve weight
    */
    function effectiveReserveWeights(Fraction memory _rate) private view returns (uint32, uint32) {
        // get the primary reserve staked balance
        uint256 primaryStakedBalance = stakedBalances[primaryReserveToken];

        // get the tokens amplified balances
        uint256 primaryBalance = reserveAmplifiedBalance(primaryReserveToken);
        uint256 secondaryBalance = reserveAmplifiedBalance(secondaryReserveToken);

        // get the new weights
        return IBancorFormula(addressOf(BANCOR_FORMULA)).balancedWeights(
            primaryStakedBalance.mul(AMPLIFICATION_FACTOR),
            primaryBalance,
            secondaryBalance,
            _rate.n,
            _rate.d);
    }

    /**
      * @dev calculates and returns the rate between two reserve tokens
      *
      * @param _token1          contract address of the token to calculate the rate of one unit of
      * @param _token2          contract address of the token to calculate the rate of one `_token1` unit in
      * @param _token1Weight    reserve weight of token1
      * @param _token2Weight    reserve weight of token2
      *
      * @return rate
    */
    function tokensRate(IERC20Token _token1, IERC20Token _token2, uint32 _token1Weight, uint32 _token2Weight) private view returns (Fraction memory) {
        // apply the amplification factor
        uint256 token1Balance = reserveAmplifiedBalance(_token1);
        uint256 token2Balance = reserveAmplifiedBalance(_token2);

        // get reserve weights
        if (_token1Weight == 0) {
            _token1Weight = reserves[_token1].weight;
        }

        if (_token2Weight == 0) {
            _token2Weight = reserves[_token2].weight;
        }

        return Fraction({ n: token2Balance.mul(_token1Weight), d: token1Balance.mul(_token2Weight) });
    }

    /**
      * @dev dispatches rate events for both reserve tokens and for the target pool token
      * only used to circumvent the `stack too deep` compiler error
      *
      * @param _sourceToken     contract address of the source reserve token
      * @param _targetToken     contract address of the target reserve token
      * @param _sourceWeight    source reserve token weight
      * @param _targetWeight    target reserve token weight
    */
    function dispatchRateEvents(IERC20Token _sourceToken, IERC20Token _targetToken, uint32 _sourceWeight, uint32 _targetWeight) private {
        dispatchTokenRateUpdateEvent(_sourceToken, _targetToken, _sourceWeight, _targetWeight);

        // dispatch the `TokenRateUpdate` event for the pool token
        // the target reserve pool token rate is the only one that's affected
        // by conversions since conversion fees are applied to the target reserve
        ISmartToken targetPoolToken = poolToken(_targetToken);
        uint256 targetPoolTokenSupply = targetPoolToken.totalSupply();
        dispatchPoolTokenRateUpdateEvent(targetPoolToken, targetPoolTokenSupply, _targetToken);
    }

    /**
      * @dev dispatches token rate update event
      * only used to circumvent the `stack too deep` compiler error
      *
      * @param _token1          contract address of the token to calculate the rate of one unit of
      * @param _token2          contract address of the token to calculate the rate of one `_token1` unit in
      * @param _token1Weight    reserve weight of token1
      * @param _token2Weight    reserve weight of token2
    */
    function dispatchTokenRateUpdateEvent(IERC20Token _token1, IERC20Token _token2, uint32 _token1Weight, uint32 _token2Weight) private {
        // dispatch token rate update event
        Fraction memory rate = tokensRate(_token1, _token2, _token1Weight, _token2Weight);

        emit TokenRateUpdate(_token1, _token2, rate.n, rate.d);
    }

    /**
      * @dev dispatches the `TokenRateUpdate` for the pool token
      * only used to circumvent the `stack too deep` compiler error
      *
      * @param _poolToken       address of the pool token
      * @param _poolTokenSupply total pool token supply
      * @param _reserveToken    address of the reserve token
    */
    function dispatchPoolTokenRateUpdateEvent(ISmartToken _poolToken, uint256 _poolTokenSupply, IERC20Token _reserveToken) private {
        emit TokenRateUpdate(_poolToken, _reserveToken, stakedBalances[_reserveToken], _poolTokenSupply);
    }

    /**
      * @dev returns the current time
    */
    function time() internal view returns (uint256) {
        return now;
    }

    uint256 private constant MAX_RATE_FACTOR_LOWER_BOUND = 1e30;
    uint256 private constant MAX_RATE_FACTOR_UPPER_BOUND = uint256(-1) / MAX_RATE_FACTOR_LOWER_BOUND;

    /**
      * @dev reduces the numerator and denominator while maintaining the ratio between them as accurately as possible
    */
    function reduceRate(uint256 _n, uint256 _d) internal pure returns (Fraction memory) {
        if (_n >= _d) {
            return reduceFactors(_n, _d);
        }

        Fraction memory rate = reduceFactors(_d, _n);
        return Fraction({ n: rate.d, d: rate.n });
    }

    /**
      * @dev reduces the factors while maintaining the ratio between them as accurately as possible
    */
    function reduceFactors(uint256 _max, uint256 _min) internal pure returns (Fraction memory) {
        if (_min > MAX_RATE_FACTOR_UPPER_BOUND) {
            return Fraction({
                n: MAX_RATE_FACTOR_LOWER_BOUND,
                d: _min / (_max / MAX_RATE_FACTOR_LOWER_BOUND)
            });
        }

        if (_max > MAX_RATE_FACTOR_LOWER_BOUND) {
            return Fraction({
                n: MAX_RATE_FACTOR_LOWER_BOUND,
                d: _min * MAX_RATE_FACTOR_LOWER_BOUND / _max
            });
        }

        return Fraction({ n: _max, d: _min });
    }
}

// File: solidity/contracts/converter/interfaces/ITypedConverterFactory.sol

pragma solidity 0.4.26;




/*
    Typed Converter Factory interface
*/
contract ITypedConverterFactory {
    function converterType() public pure returns (uint16);
    function createConverter(IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee) public returns (IConverter);
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/LiquidityPoolV2ConverterFactory.sol

pragma solidity 0.4.26;

/*
    LiquidityPoolV2Converter Factory
*/
contract LiquidityPoolV2ConverterFactory is ITypedConverterFactory {
    /**
      * @dev returns the converter type the factory is associated with
      *
      * @return converter type
    */
    function converterType() public pure returns (uint16) {
        return 2;
    }

    /**
      * @dev creates a new converter with the given arguments and transfers
      * the ownership to the caller
      *
      * @param _anchor            anchor governed by the converter
      * @param _registry          address of a contract registry contract
      * @param _maxConversionFee  maximum conversion fee, represented in ppm
      *
      * @return new converter
    */
    function createConverter(IConverterAnchor _anchor, IContractRegistry _registry, uint32 _maxConversionFee) public returns (IConverter) {
        ConverterBase converter = new LiquidityPoolV2Converter(IPoolTokensContainer(_anchor), _registry, _maxConversionFee);
        converter.transferOwnership(msg.sender);
        return converter;
    }
}

