// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;

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

// File: contracts/UAXToken.sol

/**
 * UAX Smart Contract: EIP-20 compatible token smart contract that
 * manages UAX tokens.
 */

pragma solidity ^0.4.24;




contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) public allowed;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public payable returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public payable returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public payable returns (bool) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));

        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        balances[account] = balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        balances[account] = balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

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

    uint256 constant internal FEE_DENOMINATOR = 100000;
    uint256 constant internal MAX_FEE_NUMERATOR = FEE_DENOMINATOR;
    uint256 constant internal MIN_FEE_NUMERATIOR = 0;
    uint256 constant internal MAX_TOKENS_COUNT =
    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff /
    MAX_FEE_NUMERATOR;
    uint256 constant internal DEFAULT_FEE = 5e2;
    uint256 constant internal BLACK_LIST_FLAG = 0x01;
    uint256 constant internal ZERO_FEE_FLAG = 0x02;

    modifier delegatable {
        if (depute == address(0)) {
            require(msg.value == 0);
            // Non payable if not delegated
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

    constructor(address _feeCollector) public {
        fixedFee = DEFAULT_FEE;
        minVariableFee = 0;
        maxVariableFee = 0;
        variableFeeNumerator = 0;

        owner = msg.sender;
        feeCollector = _feeCollector;
    }

    function() public delegatable payable {
        revert();
    }
    function name() public delegatable view returns (string) {
        return "UAX";
    }

    function symbol() public delegatable view returns (string) {
        return "UAX";
    }

    function decimals() public delegatable view returns (uint8) {
        return 2;
    }

    function totalSupply() public delegatable view returns (uint256) {
        return tokensCount;
    }

    function balanceOf(address _owner)
    public delegatable view returns (uint256 balance) {
        return ERC20.balanceOf(_owner);
    }

    function transfer(address _to, uint256 _value)
    public delegatable payable returns (bool) {
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

    function transferFrom(address _from, address _to, uint256 _value)
    public delegatable payable returns (bool) {
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

    function approve(address _spender, uint256 _value)
    public delegatable payable returns (bool success) {
        return ERC20.approve(_spender, _value);
    }

    function allowance(address _owner, address _spender)
    public delegatable view returns (uint256 remaining) {
        return ERC20.allowance(_owner, _spender);
    }

    function delegatedTransfer(
        address _to, uint256 _value, uint256 _fee,
        uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s)
    public delegatable payable returns (bool) {
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

    function delegatedMultiTransfer(
        address[] _to_arr, uint256[] _value_arr, uint256[] _fee_arr,
        uint256[] _nonce_arr, uint8[] _v_arr, bytes32[] _r_arr, bytes32[] _s_arr)
    public delegatable payable returns (bool) {
        require(
            _to_arr.length == _value_arr.length &&
            _to_arr.length == _fee_arr.length &&
            _to_arr.length == _nonce_arr.length &&
            _to_arr.length == _v_arr.length &&
            _to_arr.length == _r_arr.length &&
            _to_arr.length == _s_arr.length
        );

        for (uint i = 0; i < _to_arr.length; i++) {
            delegatedTransfer(_to_arr[i], _value_arr[i], _fee_arr[i], _nonce_arr[i], _v_arr[i], _r_arr[i], _s_arr[i]);
        }
    }

    function createTokens(uint256 _value)
    public delegatable payable returns (bool) {
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

    function burnTokens(uint256 _value)
    public delegatable payable returns (bool) {
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

    function freezeTransfers() public delegatable payable {
        require(msg.sender == owner);

        if (!frozen) {
            frozen = true;
            emit Freeze();
        }
    }

    function unfreezeTransfers() public delegatable payable {
        require(msg.sender == owner);

        if (frozen) {
            frozen = false;
            emit Unfreeze();
        }
    }

    function setOwner(address _newOwner) public {
        require(msg.sender == owner);

        owner = _newOwner;
    }

    function setFeeCollector(address _newFeeCollector)
    public delegatable payable {
        require(msg.sender == owner);

        feeCollector = _newFeeCollector;
    }

    function nonce(address _owner) public view delegatable returns (uint256) {
        return nonces [_owner];
    }

    function setFeeParameters(
        uint256 _fixedFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFeeNumerator) public delegatable payable {
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

    function getFeeParameters() public delegatable view returns (
        uint256 _fixedFee,
        uint256 _minVariableFee,
        uint256 _maxVariableFee,
        uint256 _variableFeeNumnerator) {
        _fixedFee = fixedFee;
        _minVariableFee = minVariableFee;
        _maxVariableFee = maxVariableFee;
        _variableFeeNumnerator = variableFeeNumerator;
    }

    function calcFee(uint256 _amount)
    public delegatable view returns (uint256 _fee) {
        require(_amount <= MAX_TOKENS_COUNT);

        _fee = _amount.mul(variableFeeNumerator) / FEE_DENOMINATOR;
        if (_fee < minVariableFee) _fee = minVariableFee;
        if (_fee > maxVariableFee) _fee = maxVariableFee;
        _fee = _fee.add(fixedFee);
    }

    function setFlags(address _address, uint256 _flags)
    public delegatable payable {
        require(msg.sender == owner);

        addressFlags [_address] = _flags;
    }

    function flags(address _address) public delegatable view returns (uint256) {
        return addressFlags [_address];
    }

    function setDepute(address _depute) public {
        require(msg.sender == owner);

        if (depute != _depute) {
            depute = _depute;
            emit Delegation(depute);
        }
    }

    function thisAddress() internal view returns (address) {
        return address(this);
    }

    function messageSenderAddress() internal view returns (address) {
        return msg.sender;
    }

    address internal owner;
    address internal feeCollector;
    uint256 internal tokensCount;
    bool internal frozen;
    mapping(address => uint256) internal nonces;
    uint256 internal fixedFee;
    uint256 internal minVariableFee;
    uint256 internal maxVariableFee;
    uint256 internal variableFeeNumerator;
    mapping(address => uint256) internal addressFlags;
    address internal depute;

    event Freeze ();
    event Unfreeze ();
    event FeeChange (
        uint256 fixedFee,
        uint256 minVariableFee,
        uint256 maxVariableFee,
        uint256 variableFeeNumerator
    );
    event Delegation (address depute);
}
