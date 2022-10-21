pragma solidity ^0.5.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Invalid value");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Invalid value");
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b, "Invalid value");
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "Invalid value");
        c = a / b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Pagstar is IERC20 {

    using SafeMath for uint256;

    address public owner;

    modifier onlyOwner {
        require(owner == msg.sender, "Sender must be owner");
        _;
    }

    event Transfer( address indexed _from, address indexed _to, uint256 _value );
    event Approval( address indexed _tokenOwner, address indexed _spender, uint256 _tokens);

    string public name = "PAGSTAR";
    string public symbol = "PSTAR";
    string public standard = "PSTAR Token";
    uint8 public decimals = 7;
    uint256 _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(uint256 totalSupply) public {
        owner = msg.sender;
        _totalSupply = totalSupply * 10 ** uint(decimals);
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _address) public view returns(uint256){
        return balances[_address];
    }

    function transfer(address _receiver, uint256 _pagstarValue) public returns(bool){
        require(_pagstarValue <= balances[msg.sender], "Invalid values");
        balances[msg.sender] = balances[msg.sender].sub(_pagstarValue);
        balances[_receiver] = balances[_receiver].add(_pagstarValue);
        emit Transfer(msg.sender, _receiver, _pagstarValue);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint256 _pagstarValue) public returns (bool){
        require(_pagstarValue <= balances[_from], "Invalid values");
        require(_pagstarValue <= allowed[_from][msg.sender], "Invalid values");
        balances[_from] = balances[_from].sub(_pagstarValue);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_pagstarValue);
        balances[_to] = balances[_to].add(_pagstarValue);
        emit Transfer(_from, _to, _pagstarValue);
        return true;
    }

    function approve(address _spender, uint256 _pagstarValue) public returns (bool){
        allowed[msg.sender][_spender] = _pagstarValue;
        emit Approval(msg.sender, _spender, _pagstarValue);
        return true;
    }

    function increaseSupply(uint256 _supply) public onlyOwner returns (bool) {
        _totalSupply = _totalSupply.add(_supply * 10 ** uint(decimals));
        balances[msg.sender] = _totalSupply;
        return true;
    }
}
