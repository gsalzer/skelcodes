pragma solidity ^0.5.11;

contract ERC20Interface {
    string public name;
    string public symbol;
    uint8 public  decimals;
    uint public totalSupply;

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddSupply(uint amount);
    event FrozenAccount(address target, bool frozen);
    event Burn(address target, uint amount);
    event MintFrozenToken(address _from, address _to, uint256 _value);

}

contract Owned {
    address internal owner;

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "caller not a admin account");
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner {
        owner = newOwer;
    }

}

contract MNC is ERC20Interface, Owned {

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => bool) public frozenAccount;

    constructor() public {
        totalSupply = 999999994 * 10 ** 18;
        name = "Magienoirecoin";
        symbol = "MNC";
        decimals = 18;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);
        success = _transfer(_from, _to, _value);
        allowed[_from][msg.sender] -= _value;
        return success;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(!frozenAccount[_from]);

        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(allowed[_from][msg.sender] >= _value);

        balanceOf[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(_from, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenAccount(_target, _freeze);
    }

    function mintFrozenToken(address _to, uint256 _value)  external onlyOwner returns (bool success) {
        success = _mintFrozenToken(_to, _value);
        return success;
    }

    function mintBatchFrozenTokens(address[] calldata accounts, uint256[] calldata amounts) external onlyOwner returns (bool) {
        require(accounts.length > 0, "mintBatchFrozenTokens: transfer should be to at least one address");
        require(accounts.length == amounts.length, "mintBatchFrozenTokens: recipients.length != amounts.length");
        for (uint256 i = 0; i < accounts.length; i++) {
            _mintFrozenToken(accounts[i], amounts[i]);
        }
        return true;
    }

    function _mintFrozenToken(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0), "mint frozen to the zero address");
        require(_to != address(this), "mint frozen to the contract address");
        require(_value > 0, "mint frozen amount should be > 0");

        allowed[_to][msg.sender] = _value;
        _transfer(msg.sender, _to, _value);
        frozenAccount[_to] = true;
        emit MintFrozenToken(msg.sender, _to, _value);
        return true;
    }
}
