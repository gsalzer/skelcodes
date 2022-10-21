// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiERC20.sol";
import "./SafeMath.sol";

contract CoinvestingDeFiERC20 is ICoinvestingDeFiERC20 {
    using SafeMath for uint;
    // Public variables
    uint8 public constant override decimals = 18;    
    string public constant override name = "Coinvesting DeFi V2";
    string public constant override symbol = "COINVEX-V2";    
    uint public override totalSupply;

    bytes32 public override DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    
    mapping(address => mapping(address => uint)) public override allowance;
    mapping(address => uint) public override balanceOf;
    mapping(address => uint) public override nonces;

    constructor() {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    // External functions
    function approve(
        address spender,
        uint value
    )
    external
    virtual 
    override
    returns (bool)
    {
        _approve(
            payable(msg.sender), 
            spender, 
            value
        );
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
    external 
    override
    {
        require(deadline >= block.timestamp, "ERC20: EXPD");
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC20: INV_SIG");
        _approve(owner, spender, value);
    }

    function transfer(
        address to,
        uint value
    )
    external
    virtual 
    override
    returns (bool)
    {
        _transfer(
            payable(msg.sender),
            to,
            value
        );
        return true;
    }

    function transferFrom(
        address from, 
        address to, 
        uint value
    ) 
    external 
    virtual 
    override 
    returns (bool) 
    {
        if (allowance[from][msg.sender] != type(uint).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(
            from, 
            to, 
            value
        );
        return true;
    }

    // Internal functions
    function _burn(
        address from,
        uint value
    )
    internal
    virtual
    {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _mint(
        address to, 
        uint value
    )
    internal 
    virtual 
    {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    // Private functions
    function _approve(
        address owner, 
        address spender, 
        uint value
    ) 
    private  
    {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    
    function _transfer(
        address from, 
        address to, 
        uint value
    ) 
    private 
    {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }
}

