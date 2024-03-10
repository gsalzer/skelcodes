pragma solidity 0.5.17;
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a && c>=b, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(a >= b, "SafeMath: subtraction overflow");
        uint c = a - b;
        return c;
    }
}
contract Itf{
    function received(address form,address to,address attach,uint value, uint data) public;
    function verify() public pure returns (uint);
}
contract ElvesToken{
    using SafeMath for uint;
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping(address => Itf) private itf;
    uint private _totalSupply = 0;
    string private _name = "ElvesToken";
    string private _symbol = "ELS";
    uint8 private _decimals = 6;
    bool private _paused = false;
    address private _owner;
    uint private _cap = 200000000000000;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    modifier IsOwner{
        require(msg.sender==_owner,"not owner");
        _;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    constructor() public {
        _owner = msg.sender;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function cap() public view returns (uint) {
        return _cap;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return _allowances[owner][spender];
    }
    function pause() public IsOwner {
        _paused = true;
    }

    function unpause() public IsOwner{
        _paused = false;
    }

    function _approve(address owner, address spender, uint value) private whenNotPaused{
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address sender, address recipient, uint amount) private whenNotPaused{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _burn(address account, uint value) private whenNotPaused{
        require(account != address(0), "ERC20: burn from the zero address");
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function mint(address account, uint amount) public IsOwner{
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply().add(amount) <= _cap, "ERC20Capped: cap exceeded");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    function burnFrom(address account, uint amount) public whenNotPaused{
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }

    function transfer(address recipient, uint amount) public whenNotPaused returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function burn(uint amount) public whenNotPaused{
        _burn(msg.sender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function approve(address spender, uint value) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    function toSend(address itf_addr,address to,address attach,uint value,uint data) external whenNotPaused{
        require(itf_addr!=address(0)&&itf[itf_addr].verify()==1000,"itf_addr invalid");
        _transfer(msg.sender,to,value);
        itf[itf_addr].received(msg.sender,to,attach,value,data);
    }
    function setItr(address addr) external IsOwner{
        itf[addr] = Itf(addr);
    }
    function getItr(address addr)external view returns(uint){
        return itf[addr].verify();
    }
}
