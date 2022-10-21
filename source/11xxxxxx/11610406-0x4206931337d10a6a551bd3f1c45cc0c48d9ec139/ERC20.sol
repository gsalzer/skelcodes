// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Permit.sol";

abstract contract ERC20 is IERC20, IERC20Permit
{
    string public override name;
    string public override symbol;
    uint8 public immutable override decimals;

    uint256 public override totalSupply;
    mapping (address => uint256) public override balanceOf;
    mapping (address => mapping(address => uint256)) public override allowance;
    mapping (address => uint256) public override nonces;

    bytes32 private immutable cachedDomainSeparator;
    uint256 private immutable cachedChainId = block.chainid;
    bytes32 private constant permitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant eip712DomainHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant versionDomainHash = keccak256(bytes("1"));
    bytes32 private immutable nameDomainHash;

    constructor(string memory _name, string memory _symbol, uint8 _decimals)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        bytes32 _nameDomainHash = keccak256(bytes(_name));
        nameDomainHash = _nameDomainHash;
        cachedDomainSeparator = keccak256(abi.encode(
            eip712DomainHash,
            _nameDomainHash,
            versionDomainHash,
            block.chainid,
            address(this)));
    }

    function approveCore(address _owner, address _spender, uint256 _amount) internal virtual returns (bool)
    {
        allowance[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool)
    {
        return approveCore(msg.sender, _spender, _amount);
    }

    function increaseAllowance(address _spender, uint256 _toAdd) public virtual override returns (bool)
    {
        return approve(_spender, allowance[msg.sender][_spender] + _toAdd);
    }
    
    function decreaseAllowance(address _spender, uint256 _toRemove) public virtual override returns (bool)
    {
        return approve(_spender, allowance[msg.sender][_spender] - _toRemove);
    }

    function transfer(address _to, uint256 _amount) public virtual override returns (bool)
    {
        return transferCore(msg.sender, _to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool)
    {
        uint256 oldAllowance = allowance[_from][msg.sender];
        require (oldAllowance >= _amount, "Insufficient allowance");
        if (oldAllowance != type(uint256).max) {
            allowance[_from][msg.sender] = oldAllowance - _amount;
        }
        return transferCore(_from, _to, _amount);
    }

    function transferCore(address _from, address _to, uint256 _amount) internal virtual returns (bool)
    {
        require (_from != address(0));
        if (_to == address(0)) {
            burnCore(_from, _amount);
            return true;
        }
        uint256 oldBalance = balanceOf[_from];
        require (oldBalance >= _amount, "Insufficient balance");
        balanceOf[_from] = oldBalance - _amount;
        balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function mintCore(address _to, uint256 _amount) internal virtual
    {
        require (_to != address(0));

        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function burnCore(address _from, uint256 _amount) internal virtual
    {
        uint256 oldBalance = balanceOf[_from];
        require (oldBalance >= _amount, "Insufficient balance");
        balanceOf[_from] = oldBalance - _amount;
        totalSupply -= _amount;
        emit Transfer(_from, address(0), _amount);
    }

    function burn(uint256 _amount) public override
    {
        burnCore(msg.sender, _amount);
    }

    function DOMAIN_SEPARATOR() public override view returns (bytes32) 
    {
        if (block.chainid == cachedChainId) {
            return cachedDomainSeparator;
        }
        return keccak256(abi.encode(
            eip712DomainHash,
            nameDomainHash,
            versionDomainHash,
            block.chainid,
            address(this)));
    }

    function getSigningHash(bytes32 _dataHash) internal view returns (bytes32) 
    {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), _dataHash));
    }

    function permit(address _owner, address _spender, uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public virtual override
    {
        require (block.timestamp <= _deadline, "Deadline expired");

        uint256 nonce = nonces[_owner];
        bytes32 hash = getSigningHash(keccak256(abi.encode(permitTypeHash, _owner, _spender, _amount, nonce, _deadline)));
        address signer = ecrecover(hash, _v, _r, _s);
        require (signer == _owner && signer != address(0), "Invalid signature");
        nonces[_owner] = nonce + 1;
        approveCore(_owner, _spender, _amount);
    }
}
