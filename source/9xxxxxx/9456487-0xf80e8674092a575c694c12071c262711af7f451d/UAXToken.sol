/**
 * UAX Smart Contract: EIP-20 compatible token smart contract that
 * manages UAX tokens.
 */

pragma solidity ^0.4.24;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

    uint256 private _totalSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public payable returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public payable returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public payable returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when allowed_[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    /**
    * @dev Transfer token for a specified addresses
    * @param from The address to transfer from.
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        balances[account] = balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        allowed[account][msg.sender] = allowed[account][msg.sender].sub(value);
        _burn(account, value);
        emit Approval(account, msg.sender, allowed[account][msg.sender]);
    }
}

/*
 * UAX Token Smart Contract.
 * Copyright (c) 2019
 */

contract UAXToken is ERC20 {
    /**
     * Fee denominator (0.001%).
     */
    uint256 constant internal FEE_DENOMINATOR = 100000;

    /**
     * Maximum fee numerator (100%).
     */
    uint256 constant internal MAX_FEE_NUMERATOR = FEE_DENOMINATOR;

    /**
     * Minimum fee numerator (0%).
     */
    uint256 constant internal MIN_FEE_NUMERATIOR = 0;

    /**
     * Maximum allowed number of tokens in circulation.
     */
    uint256 constant internal MAX_TOKENS_COUNT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff /
    MAX_FEE_NUMERATOR;

    /**
     * Default transfer fee.
     */
    uint256 constant internal DEFAULT_FEE = 5e2;

    /**
     * Address flag that marks black listed addresses.
     */
    uint256 constant internal BLACK_LIST_FLAG = 0x01;

    /**
     * Address flag that marks zero fee addresses.
     */
    uint256 constant internal ZERO_FEE_FLAG = 0x02;

    modifier deputable {
        if (depute == address(0)) {
            require(msg.value == 0);
            // Non payable if not deputed
            _;
        } else {
            assembly {
            // Save owner
                let oldOwner := sload (owner_slot)

            // Save depute
                let oldDepute := sload (depute_slot)

            // Solidity stores address of the beginning of free memory at 0x40
                let buffer := mload (0x40)

            // Copy message call data into buffer
                calldatacopy (buffer, 0, calldatasize)

            // Lets call our depute
                let result := delegatecall (gas, oldDepute, buffer, calldatasize, buffer, 0)

            // Check, whether owner was changed
                switch eq (oldOwner, sload (owner_slot))
                case 1 {} // Owner was not changed, fine
                default {revert (0, 0)} // Owner was changed, revert!

            // Check, whether depute was changed
                switch eq (oldDepute, sload (depute_slot))
                case 1 {} // Depute was not changed, fine
                default {revert (0, 0)} // Depute was changed, revert!

            // Copy returned value into buffer
                returndatacopy (buffer, 0, returndatasize)

            // Check call status
                switch result
                case 0 {revert (buffer, returndatasize)} // Call failed, revert!
                default {return (buffer, returndatasize)} // Call succeeded, return
            }
        }
    }

    /**
     * Create UAX Token smart contract with message sender as an owner.
     *
     * @param _feeCollector address fees are sent to
     */
    constructor(address _feeCollector) public {
        fixedFee = DEFAULT_FEE;
        minVariableFee = 0;
        maxVariableFee = 0;
        variableFeeNumerator = 0;

        owner = msg.sender;
        feeCollector = _feeCollector;
    }

    /**
     * Depute unrecognized functions.
     */
    function() public deputable payable {
        revert();
        // Revert if not deputed
    }

    /**
     * Get name of the token.
     *
     * @return name of the token
     */
    function name() public deputable view returns (string) {
        return "UAX Token";
    }

    /**
     * Get symbol of the token.
     *
     * @return symbol of the token
     */
    function symbol() public deputable view returns (string) {
        return "UAX";
    }

    /**
     * Get number of decimals for the token.
     *
     * @return number of decimals for the token
     */
    function decimals() public deputable view returns (uint8) {
        return 2;
    }

    /**
     * Get total number of tokens in circulation.
     *
     * @return total number of tokens in circulation
     */
    function totalSupply() public deputable view returns (uint256) {
        return tokensCount;
    }

    /**
     * Get number of tokens currently belonging to given owner.
     *
     * @param _owner address to get number of tokens currently belonging to the
     *        owner of
     * @return number of tokens currently belonging to the owner of given address
     */
    function balanceOf(address _owner)
    public deputable view returns (uint256 balance) {
        return ERC20.balanceOf(_owner);
    }

    /**
     * Transfer given number of tokens from message sender to given recipient.
     *
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer to the owner of given address
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transfer(address _to, uint256 _value)
    public deputable payable returns (bool) {
        if (frozen) return false;
        else if (
            (addressFlags [msg.sender] | addressFlags [_to]) & BLACK_LIST_FLAG ==
            BLACK_LIST_FLAG)
            return false;
        else {
            if (_value <= balances[msg.sender]) {
                require(ERC20.transfer(_to, _value));
                return true;
            } else return false;
        }
    }

    /**
     * Transfer given number of tokens from given owner to given recipient.
     *
     * @param _from address to transfer tokens from the owner of
     * @param _to address to transfer tokens to the owner of
     * @param _value number of tokens to transfer from given owner to given
     *        recipient
     * @return true if tokens were transferred successfully, false otherwise
     */
    function transferFrom(address _from, address _to, uint256 _value)
    public deputable payable returns (bool) {
        if (frozen) {
            return false;
        }
        else if (
            (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
            BLACK_LIST_FLAG) {
            return false;
        }
        else {
            if (_value <= allowed[_from][msg.sender] && _value <= balances[_from]) {
                require(ERC20.transferFrom(_from, _to, _value));
                return true;
            } else return false;
        }
    }

    /**
     * Allow given spender to transfer given number of tokens from message sender.
     *
     * @param _spender address to allow the owner of to transfer tokens from
     *        message sender
     * @param _value number of tokens to allow to transfer
     * @return true if token transfer was successfully approved, false otherwise
     */
    function approve(address _spender, uint256 _value)
    public deputable payable returns (bool success) {
        return ERC20.approve(_spender, _value);
    }

    /**
     * Tell how many tokens given spender is currently allowed to transfer from
     * given owner.
     *
     * @param _owner address to get number of tokens allowed to be transferred
     *        from the owner of
     * @param _spender address to get number of tokens allowed to be transferred
     *        by the owner of
     * @return number of tokens given spender is currently allowed to transfer
     *         from given owner
     */
    function allowance(address _owner, address _spender)
    public deputable view returns (uint256 remaining) {
        return ERC20.allowance(_owner, _spender);
    }

    /**
     * Transfer given number of token from the signed defined by digital signature
     * to given recipient.
     *
     * @param _to address to transfer token to the owner of
     * @param _value number of tokens to transfer
     * @param _fee number of tokens to give to message sender
     * @param _nonce nonce of the transfer
     * @param _v parameter V of digital signature
     * @param _r parameter R of digital signature
     * @param _s parameter S of digital signature
     */
    function deputedTransfer(
        address _to, uint256 _value, uint256 _fee,
        uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
    public deputable payable returns (bool) {
        if (frozen) return false;
        else {
            address _from = ecrecover(
                keccak256(thisAddress(), messageSenderAddress(), _to, _value, _fee, _nonce),
                _v, _r, _s
            );

            if (_nonce != nonces [_from]) {
                return false;
            }
            if (
                (addressFlags [_from] | addressFlags [_to]) & BLACK_LIST_FLAG ==
                BLACK_LIST_FLAG) {
                return false;
            }

            uint256 fee =
            (addressFlags [_from] | addressFlags [_to]) & ZERO_FEE_FLAG == ZERO_FEE_FLAG ?
            0 :
            calcFee(_value);

            uint256 balance = balances[_from];
            if (_value > balance) {
                return false;
            }
            balance = balance.sub(_value);
            if (fee > balance) {
                return false;
            }
            balance = balance.sub(fee);
            if (_fee > balance) {
                return false;
            }

            balance = balance.sub(_fee);

            nonces [_from] = _nonce + 1;

            balances[_from] = balance;
            balances[_to] = balances[_to].add(_value);
            balances[feeCollector] = balances[feeCollector].add(fee);
            balances[msg.sender] = balances[msg.sender].add(_fee);

            emit Transfer(_from, _to, _value);
            emit Transfer(_from, feeCollector, fee);
            emit Transfer(_from, msg.sender, _fee);

            return true;
        }
    }

    /**
     * Multiple deputedTransfer
     *
     * @param _to_arr address to transfer token to the owner of
     * @param _value_arr number of tokens to transfer
     * @param _fee_arr number of tokens to give to message sender
     * @param _nonce_arr nonce of the transfer
     * @param _v_arr parameter V of digital signature
     * @param _r_arr parameter R of digital signature
     * @param _s_arr parameter S of digital signature
     */
    function deputedMultiTransfer(
        address[] _to_arr, uint256[] _value_arr, uint256[] _fee_arr,
        uint256[] _nonce_arr, uint8[] _v_arr, bytes32[] _r_arr, bytes32[] _s_arr)
    public deputable payable returns (bool) {
        require(
            _to_arr.length == _value_arr.length &&
            _to_arr.length == _fee_arr.length &&
            _to_arr.length == _nonce_arr.length &&
            _to_arr.length == _v_arr.length &&
            _to_arr.length == _r_arr.length &&
            _to_arr.length == _s_arr.length
        );

        for (uint i = 0; i < _to_arr.length; i++) {
            deputedTransfer(_to_arr[i], _value_arr[i], _fee_arr[i], _nonce_arr[i], _v_arr[i], _r_arr[i], _s_arr[i]);
        }
    }

    /**
     * Create tokens.
     *
     * @param _value number of tokens to be created.
     */

    function createTokens(uint256 _value)
    public deputable payable returns (bool) {
        require(msg.sender == owner);

        if (_value > 0) {
            if (_value <= MAX_TOKENS_COUNT.sub(tokensCount)) {
                balances[msg.sender] = balances[msg.sender].add(_value);
                tokensCount = tokensCount.add(_value);

                emit Transfer(address(0), msg.sender, _value);
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * Burn tokens.
     *
     * @param _value number of tokens to burn
     */
    function burnTokens(uint256 _value)
    public deputable payable returns (bool) {
        require(msg.sender == owner);

        if (_value > 0) {
            if (_value <= balances[msg.sender]) {
                balances[msg.sender] = balances[msg.sender].sub(_value);
                tokensCount = tokensCount.sub(_value);

                emit Transfer(msg.sender, address(0), _value);

                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * Freeze token transfers.
     */
    function freezeTransfers() public deputable payable {
        require(msg.sender == owner);

        if (!frozen) {
            frozen = true;
            emit Freeze();
        }
    }

    /**
     * Unfreeze token transfers.
     */
    function unfreezeTransfers() public deputable payable {
        require(msg.sender == owner);

        if (frozen) {
            frozen = false;
            emit Unfreeze();
        }
    }

    /**
     * Set smart contract owner.
     *
     * @param _newOwner address of the new owner
     */
    function setOwner(address _newOwner) public {
        require(msg.sender == owner);

        owner = _newOwner;
    }

    /**
     * Set fee collector.
     *
     * @param _newFeeCollector address of the new fee collector
     */
    function setFeeCollector(address _newFeeCollector)
    public deputable payable {
        require(msg.sender == owner);

        feeCollector = _newFeeCollector;
    }

    /**
     * Get current nonce for token holder with given address, i.e. nonce this
     * token holder should use for next deputed transfer.
     *
     * @param _owner address of the token holder to get nonce for
     * @return current nonce for token holder with give address
     */
    function nonce(address _owner) public view deputable returns (uint256) {
        return nonces [_owner];
    }

    /**
     * Set fee parameters.
     *
     * @param _fixedFee fixed fee in token units
     * @param _minVariableFee minimum variable fee in token units
     * @param _maxVariableFee maximum variable fee in token units
     * @param _variableFeeNumerator variable fee numerator
     */
    function setFeeParameters(
        uint256 _fixedFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFeeNumerator) public deputable payable {
        require(msg.sender == owner);

        require(_minVariableFee <= _maxVariableFee);
        require(_variableFeeNumerator <= MAX_FEE_NUMERATOR);

        fixedFee = _fixedFee;
        minVariableFee = _minVariableFee;
        maxVariableFee = _maxVariableFee;
        variableFeeNumerator = _variableFeeNumerator;

        emit FeeChange(
            _fixedFee, _minVariableFee, _maxVariableFee, _variableFeeNumerator
        );
    }

    /**
     * Get fee parameters.
     *
     * @return fee parameters
     */
    function getFeeParameters() public deputable view returns (
        uint256 _fixedFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFeeNumnerator) {
        _fixedFee = fixedFee;
        _minVariableFee = minVariableFee;
        _maxVariableFee = maxVariableFee;
        _variableFeeNumnerator = variableFeeNumerator;
    }

    /**
     * Calculate fee for transfer of given number of tokens.
     *
     * @param _amount transfer amount to calculate fee for
     * @return fee for transfer of given amount
     */
    function calcFee(uint256 _amount)
    public deputable view returns (uint256 _fee) {
        require(_amount <= MAX_TOKENS_COUNT);

        _fee = _amount.mul(variableFeeNumerator) / FEE_DENOMINATOR;
        if (_fee < minVariableFee) _fee = minVariableFee;
        if (_fee > maxVariableFee) _fee = maxVariableFee;
        _fee = _fee.add(fixedFee);
    }

    /**
     * Set flags for given address.
     *
     * @param _address address to set flags for
     * @param _flags flags to set
     */
    function setFlags(address _address, uint256 _flags)
    public deputable payable {
        require(msg.sender == owner);

        addressFlags [_address] = _flags;
    }

    /**
     * Get flags for given address.
     *
     * @param _address address to get flags for
     * @return flags for given address
     */
    function flags(address _address) public deputable view returns (uint256) {
        return addressFlags [_address];
    }

    /**
     * Set address of smart contract to depute execution of deputable methods
     * to.
     *
     * @param _depute address of smart contract to depute execution of
     * deputable methods to, or zero to not depute deputable methods
     * execution.
     */

    function setDepute(address _depute) public {
        require(msg.sender == owner);

        if (depute != _depute) {
            depute = _depute;
            emit Delegation(depute);
        }
    }

    /**
     * Get address of this smart contract.
     *
     * @return address of this smart contract
     */
    function thisAddress() internal view returns (address) {
        return address(this);
    }

    /**
     * Get address of message sender.
     *
     * @return address of this smart contract
     */
    function messageSenderAddress() internal view returns (address) {
        return msg.sender;
    }

    /**
     * Owner of the smart contract.
     */
    address internal owner;

    /**
     * Address where fees are sent to.
     */
    address internal feeCollector;

    /**
     * Number of tokens in circulation.
     */
    uint256 internal tokensCount;

    /**
     * Whether token transfers are currently frozen.
     */
    bool internal frozen;

    /**
     * Mapping from sender's address to the next deputed transfer nonce.
     */
    mapping(address => uint256) internal nonces;

    /**
     * Fixed fee amount in token units.
     */
    uint256 internal fixedFee;

    /**
     * Minimum variable fee in token units.
     */
    uint256 internal minVariableFee;

    /**
     * Maximum variable fee in token units.
     */
    uint256 internal maxVariableFee;

    /**
     * Variable fee numerator.
     */
    uint256 internal variableFeeNumerator;

    /**
     * Maps address to its flags.
     */
    mapping(address => uint256) internal addressFlags;

    /**
     * Address of smart contract to depute execution of deputable methods to,
     * or zero to not depute deputable methods execution.
     */
    address internal depute;

    /**
     * Logged when token transfers were frozen.
     */
    event Freeze ();

    /**
     * Logged when token transfers were unfrozen.
     */
    event Unfreeze ();

    /**
     * Logged when fee parameters were changed.
     *
     * @param fixedFee fixed fee in token units
     * @param minVariableFee minimum variable fee in token units
     * @param maxVariableFee maximum variable fee in token units
     * @param variableFeeNumerator variable fee numerator
     */
    event FeeChange (
        uint256 fixedFee,
        uint256 minVariableFee,
        uint256 maxVariableFee,
        uint256 variableFeeNumerator
    );

    /**
     * Logged when address of smart contract execution of deputable methods is
     * deputed to was changed.
     *
     * @param depute new address of smart contract execution of deputable
     * methods is deputed to or zero if execution of deputable methods is
     * oot deputed.
     */
    event Delegation (address depute);
}
