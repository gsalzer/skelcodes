pragma solidity ^0.5.13;

import "./ERC20Interface.sol";
import "./SafeMath.sol";
import "./AddressSet.sol";

contract ERC20 is ERC20Interface {
    using SafeMath for uint256;
    using AddressSet for AddressSet.addrset;
    AddressSet.addrset internal holders;

    string  internal tokenName;
    string  internal tokenSymbol;
    uint8   internal tokenDecimals;
    uint256 internal tokenTotalSupply;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowed;

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply)
        internal
    {
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals;
        _mint(msg.sender, _totalSupply);
    }

    function approve(address _spender, uint256 _amount)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _delta)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].sub(_delta));
        return true;
    }

    function increaseAllowance(address _spender, uint256 _delta)
        public
        returns (bool success)
    {
        _approve(msg.sender, _spender, allowed[msg.sender][_spender].add(_delta));
        return true;
    }

    function transfer(address _to, uint256 _amount)
        public
        returns (bool success)
    {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool success)
    {
        _transfer(_from, _to, _amount);
        _approve(_from, msg.sender, allowed[_from][msg.sender].sub(_amount));
        return true;
    }

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    function balanceOf(address _owner)
        public
        view
        returns (uint256 balance)
    {
        return balances[_owner];
    }

    function decimals()
        public
        view
        returns (uint8)
    {
        return tokenDecimals;
    }

    function name()
        public
        view
        returns (string memory)
    {
        return tokenName;
    }

    function symbol()
        public
        view
        returns (string memory)
    {
        return tokenSymbol;
    }

    function totalSupply()
        public
        view
        returns (uint256)
    {
        return tokenTotalSupply;
    }

    function _approve(address _owner, address _spender, uint256 _amount)
        internal
    {
        allowed[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _burn(address _from, uint256 _amount)
        internal
    {
        balances[_from] = balances[_from].sub(_amount);
        tokenTotalSupply = tokenTotalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);
        emit Burn(_from, _amount);
    }

    function _mint(address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(_to != address(this), "ERC20: mint to token contract");

        tokenTotalSupply = tokenTotalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(address(0), _to, _amount);
        emit Mint(_to, _amount);
    }

    function _transfer(address _from, address _to, uint256 _amount)
        internal
    {
        require(_to != address(0), "ERC20: transfer to the zero address");
        require(_to != address(this), "ERC20: transfer to token contract");

        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        if (balances[_to] > 0) holders.insert(_to);
        if (balances[_from] == 0) holders.remove(_from);
        emit Transfer(_from, _to, _amount);
    }

    function holderCount()
        public
        view
        returns (uint)
    {
        return holders.elements.length;
    }
}

