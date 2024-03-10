pragma solidity 0.5.14;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: Addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: Subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: Modulo by zero");
        return a % b;
    }
}

contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ETHERZ is ERC20 {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public etherzAddress;
    uint256 public circulatingSupply;

    mapping (address => uint256)  balances;
    mapping (address => mapping (address => uint256))  allowed;

    constructor () public {
        symbol = "EZC";
        name = "ETHERZ";
        decimals = 18;
        owner = msg.sender;
        totalSupply = 60000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
  
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Null address");
        require(_value <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0), "Null address");
        require(_to != address(0), "Null address");
        require(_value <= balances[_from], "Invalid balance");
        require(_value <= allowed[_from][msg.sender], "Invalid allowance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Null address");
        require(_value > 0, "Null value");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }  

    function updateOwner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Null Address");
        owner = _newOwner;
        return true;
    }
    
    function updateEtherzAddress(address _newEtherzAddress) public onlyOwner returns(bool) {
        require(_newEtherzAddress != address(0), "Null Address");
        etherzAddress = _newEtherzAddress;
        return true;
    }
    
    function mint(address _receiver, uint256 _value) public returns (bool) {
        require(_receiver != address(0), "Null address");
        require(_value >= 0, "Null amount");
        require(msg.sender == etherzAddress, "Only from etherz");
        require(totalSupply >= circulatingSupply + _value, "Amount greater than totalSupply");
        totalSupply = totalSupply.add(_value);
        balances[_receiver] = balances[_receiver].add(_value);
        circulatingSupply = circulatingSupply + _value;
        emit Transfer(address(0), _receiver, _value);
        return true;
    }

    function ownerMint(uint256 _value) public onlyOwner returns (bool) {
        require(_value >= 0, "Null amount");
        require(totalSupply >= circulatingSupply + _value, "Amount greater than totalSupply");
        circulatingSupply = circulatingSupply.add(_value);
        balances[owner] = balances[owner].add(_value);
        emit Transfer(address(0), owner, _value);
        return true;
    }
}
