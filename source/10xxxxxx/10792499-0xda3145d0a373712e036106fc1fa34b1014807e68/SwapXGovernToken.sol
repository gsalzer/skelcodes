pragma solidity ^0.5.16;

import './SafeMath.sol';
import "./Ownable.sol";
import "./IERC20.sol";

contract SwapXGovernToken is Ownable, IERC20{

    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    uint256 internal _maxSupply;
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    mapping(address => bool) internal issuer;

    modifier onlyIssuer() {
        require(issuer[msg.sender], "The caller does not have issuer role privileges");
        _;
    }

    constructor (string memory name, string memory sym, uint256 maxSupply) public {
        _name = name;
        _symbol = sym;
        _decimals = 18;

        if (maxSupply != 0) {
            _maxSupply = maxSupply;
        }

        owner = msg.sender;
        issuer[msg.sender] = true;
    }


    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        //        require(!frozen[sender] && !frozen[recipient] && !frozen[msg.sender], "address frozen");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        //        require(!frozen[spender] && !frozen[msg.sender], "address frozen");
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        //        require(!frozen[spender] && !frozen[msg.sender], "address frozen");
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    function issue(address account, uint256 amount) external onlyIssuer returns (bool) {
        _mint(account, amount);
        return true;
    }

    function redeem(address account, uint256 amount) external onlyIssuer returns (bool) {
        _burn(account, amount);
        return true;
    }

    function addIssuer(address _addr) public onlyOwner returns (bool){
        require(_addr != address(0), "address cannot be 0");
        if(issuer[_addr] == false) {
            issuer[_addr] = true;
            return true;
        }
        return false;
    }

    function removeIssuer(address _addr) public onlyOwner returns (bool) {
        require(_addr != address(0), "address cannot be 0");
        if(issuer[_addr] == true) {
            issuer[_addr] = false;
            return true;
        }
        return false;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);

        require(_totalSupply <= _maxSupply, "ERC20: supply amount cannot over maxSupply");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address _owner, address spender, uint256 value) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

