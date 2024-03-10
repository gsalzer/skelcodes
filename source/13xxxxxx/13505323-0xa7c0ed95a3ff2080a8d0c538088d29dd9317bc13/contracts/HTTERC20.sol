// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IHTTERC20.sol";
import "./interfaces/IHTTPrivateSale.sol";
import "./libraries/SafeMath.sol";
import "./access/Ownable.sol";

contract HTTERC20 is IHTTERC20, Ownable {
    using SafeMath for uint256;

    string constant _name = "HiTrade Token";
    string constant _symbol = "HTT";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1_000_000_000e18;

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) public _nonces;

    bytes32 public _DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant _PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    constructor() {
        uint256 chainId;
        address owner = msg.sender;
        assembly {
            chainId := chainid()
        }
        _balances[owner] = uint96(_totalSupply);
        emit Transfer(address(0), owner, _totalSupply);
        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _burn(address from, uint256 value) internal {
        require(_balances[from] >= value, "ERC20: burn amount exceeds balance");
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function name() public pure virtual override returns (string memory) {
        return _name;
    }

    function symbol() public pure virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function DOMAIN_SEPARATOR() public view virtual override returns (bytes32) {
        return _DOMAIN_SEPARATOR;
    }

    function PERMIT_TYPEHASH() public pure virtual override returns (bytes32) {
        return _PERMIT_TYPEHASH;
    }

    function burn(uint256 amount) external override onlyOwner {
        _burn(msg.sender, amount);
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function nonces(address owner) external view override returns (uint256) {
        return _nonces[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (_allowances[from][msg.sender] != type(uint256).max) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
                value
            );
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "HTT: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        _PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        _nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "HTT: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }
}

