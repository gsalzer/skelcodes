pragma solidity ^0.5.14;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}
contract ERC20 {
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function transfer(address to, uint256 value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract XProtocalToken is ERC20 {
    using SafeMath for uint256;
    string  public constant name = "X Protocal";
    string  public constant symbol = "XPT";
    uint256 public totalSupply;
    address public owner;
    address private contractAddress;
    bytes32 private secretPhase;
    bool public isEnabled = false;
    uint public sellEndTime = now + 426 days;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);
    constructor (bytes32 _secretPhase) public {
        owner = msg.sender;
        secretPhase = _secretPhase;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    modifier onlyContract() {
        require(msg.sender == contractAddress, "Only contract");
        _;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "not enough balance");
        require (isEnabled, "cannot send token at this point");                   // Check if sender is frozen
        require(!frozenAccount[_to]); 
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function mint(address _to, uint256 _value, bytes32 _secretPhase) public onlyContract returns (bool success) {
        require(secretPhase == _secretPhase, "sorry wrong secrat");
        if (sellEndTime <= now) {
            return false;
        }
        totalSupply += _value;
        balanceOf[_to] += _value;
        return true;
    }
    function setContractAddress(address _contractAddress) public onlyOwner {
        contractAddress = _contractAddress;
    }
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "from error");
        require(_value <= allowance[_from][msg.sender], "allowance");
        require (isEnabled, "cannot send token at this point");
        require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]); 
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function changeowner(address _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "Invalid Address");
        owner = _newOwner;
        return true;
    }
    function setTokenStatus() onlyOwner public {
        require(!isEnabled, "can not unlock");
        isEnabled = true;
        if(isEnabled) {
            balanceOf[owner] += (totalSupply.mul(20)).div(100);
            totalSupply += (totalSupply.mul(20)).div(100);   
        }
    }
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    function () external payable {
        revert();
    }
}
