pragma solidity ^0.4.26;

contract Iq {
    // erc20 totalSupply, total amount of tokens
    uint256 public totalSupply = 7000000000000000000000000;
    // erc20 balanceOf, balance[address]
    mapping (address => uint256) public balanceOf;
    // erc20 allowance, for transferFrom, value[owner][spender]
    mapping (address => mapping (address => uint256)) public allowance;
    // erc20 name, optional
    string public name = "Iq invest token";
    // erc20 symbol, optional
    string public symbol = "IQI";
    // erc20 decimals, optional
    uint8 public constant decimals = 18;
    // first stage control
    address public owner;
    bool public decentralized = false;

    // erc20 transfer event
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // erc20 approval event
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    // second stage event
    event Decentralize();

    modifier hasControl {
        require(msg.sender == owner);
        require(!decentralized);
        _;
    }

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    // erc20 transfer, send <_value> tokens from sender to <_to>
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(_to != address(0));
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // erc20 transferFrom, send <_value> tokens from <_from> to <_to>
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowance[_from][msg.sender] >= _value);
        require(balanceOf[_from] >= _value);
        require(_to != address(0));
        allowance[_from][msg.sender] -= _value;
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    // erc20 approve, sender approves <_spender> to spend his <_value> tokens using transferFrom
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // first stage control
    // increase amount of tokens
    function mint(address _to, uint256 _value) public hasControl {
        require(_to != address(0));
        balanceOf[_to] += _value;
        totalSupply += _value;
        emit Transfer(address(0), _to, _value);
    }

    // decrease amount of tokens
    function burn(address _from, uint256 _value) public hasControl {
        require(balanceOf[_from] >= _value);
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
    }

    // change owner
    function setOwner(address _owner) public hasControl {
        require(_owner != address(0));
        owner = _owner;
    }

    // destroy
    function kill() public hasControl {
        selfdestruct(owner);
    }

    // stage two
    function decentralize() public hasControl {
        owner = address(this);
        decentralized = true;
        emit Decentralize();
    }

    // keep clean from other tokens
    function clean(address _contract, uint256 _value) public {
        Token(_contract).transfer(msg.sender, _value);
    }
}

interface Token {
    function transfer(address _to, uint256 _value) external;
}
