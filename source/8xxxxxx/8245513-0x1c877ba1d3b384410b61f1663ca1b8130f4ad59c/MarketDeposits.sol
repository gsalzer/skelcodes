// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: contracts/interface/MarketDepositsInterface.sol

pragma solidity 0.4.24;

contract MarketDepositsInterface {
    function approve(address _sender, uint256 _value) external;
    function spend(address _depositor, address _to, uint256 _value) external;
    function withdraw(address _to, uint256 _value) external;
}

// File: contracts/MarketDeposits.sol

pragma solidity 0.4.24;




contract MarketDeposits is MarketDepositsInterface {

    address public token;
    address public poolOwners;

    mapping(address => mapping(address => uint256)) public approvals;
    mapping(address => uint256) public deposits;

    using SafeMath for uint256;

    event Deposit(address indexed depositor, uint256 value);
    event Spend(address indexed depositor, address indexed to, uint256 value);
    event Withdraw(address indexed depositor, address indexed to, uint256 value);
    event Approval(address indexed depositor, address indexed spender, uint256 value);
    event Disapproval(address indexed depositor, address indexed spender, uint256 value);

    constructor(address _token, address _poolOwners) public {
        token = _token;
        poolOwners = _poolOwners;
    }

    function onTokenTransfer(address, uint256 _value, bytes _data) external {
        require(msg.sender == address(token), "Only internal token transfers can execute this method");

        address dataSender = _bytesToAddress(_data);
        require(dataSender != address(0), "Empty depositor address in the token transfer");
        deposits[dataSender] = deposits[dataSender].add(_value);

        emit Deposit(dataSender, _value);
    }

    function approve(address _spender, uint256 _value) external {
        require(_value != 0, "Cannot approve zero");
        require(deposits[msg.sender] >= _value, "Insufficient balance");
        approvals[msg.sender][_spender] = approvals[msg.sender][_spender].add(_value);

        emit Approval(msg.sender, _spender, _value);
    }

    function disapprove(address _spender, uint256 _value) external {
        require(_value != 0, "Cannot disapprove zero");
        require(approvals[msg.sender][_spender] >= _value, "Insufficient approved");
        approvals[msg.sender][_spender] = approvals[msg.sender][_spender].sub(_value);

        emit Disapproval(msg.sender, _spender, _value);
    }

    function spend(address _depositor, address _to, uint256 _value) external {
        require(_value != 0, "Cannot spend zero");
        require(approvals[_depositor][msg.sender] >= _value, "Address isn't an authorised spender");
        require(deposits[_depositor] >= _value, "Depositor has an insufficient balance");

        approvals[_depositor][msg.sender] = approvals[_depositor][msg.sender].sub(_value);
        deposits[_depositor] = deposits[_depositor].sub(_value);
        if (_to == address(0)) {
            ERC20(token).transfer(poolOwners, _value);
            emit Spend(_depositor, poolOwners, _value);
        } else {
            ERC20(token).transfer(_to, _value);
            emit Spend(_depositor, _to, _value);
        }
    }

    function withdraw(address _to, uint256 _value) external {
        require(_value != 0, "Cannot withdraw zero");
        require(deposits[msg.sender] >= _value, "Insufficient balance");

        deposits[msg.sender] = deposits[msg.sender].sub(_value);
        ERC20(token).transfer(_to, _value);
        emit Withdraw(msg.sender, _to, _value);
    }

    function _bytesToAddress(bytes bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }
}
