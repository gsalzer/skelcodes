pragma solidity ^0.6.3;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract ERC20 is IERC20 {
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    uint256 public totalSupply;

    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value)
        external
        override
        returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function allowance(address _owner, address _spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint256 _value) external override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value)
        external
        override
        returns (bool success)
    {
        if (
            balances[_from] >= _value &&
            allowed[_from][msg.sender] >= _value &&
            _value > 0
        ) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}

contract HumanStandardToken is ERC20 {
    fallback() external {
        revert();
    }

    string public name;
    uint8 public decimals;
    string public symbol; 

    constructor (
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount; 
        totalSupply = _initialAmount; 
        name = _tokenName; 
        decimals = _decimalUnits;
        symbol = _tokenSymbol;
    }
}


