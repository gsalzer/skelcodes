pragma solidity ^0.4.23;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract SafeMath {
    constructor() public {
    }

    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

contract TokenERC20{
    
    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public;

    function burn(uint256 _value) public returns (bool success);

    function burnFrom(address _from, uint256 _value) public returns (bool success);
    
    function mintToken(address target, uint256 mintedAmount)  public;

    function freezeAccount(address target, bool freeze)  public;
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice)  public;
    
    function transferOwnership(address newOwner)  public;
    
}

/******************************************/
/*       ADVANCED TOKEN STARTS HERE       */
/******************************************/

contract SpecialToken is SafeMath,owned {

    /* errc20 contractAddress */
    address public tokenAddr = 0x2108C55Ec6E6cC08De753aD94297400818065F9F;
    
    address public contractAddr = 0x3e895D5Fef09DaB60575AfE6801fAc965AF0e61E;
    
    address public silkAddr = 0xaD046e5DB29451b57C8D204321E71ea2db08c7dc;
  
    uint8 public vMintToken = 0;
    uint8 public vFreezeAccount = 0;
    uint8 public vSetPrices = 0;


    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(
       
    ) public {
       
    }

    function mintToken(address target, uint256 mintedAmount) public {
        if(vMintToken == 0){
            require(msg.sender == contractAddr);
            vMintToken = 1;
        }else if(vMintToken == 1){
            require(msg.sender == silkAddr);
            vMintToken = 0;
            TokenERC20(tokenAddr).mintToken(target, mintedAmount);
        }
        
    }

    function freezeAccount(address target, bool freeze)  public {
        if(vFreezeAccount == 0){
            require(msg.sender == contractAddr);
            vFreezeAccount = 1;
        } else if(vFreezeAccount == 1){
            require(msg.sender == silkAddr);
            vFreezeAccount = 0;
            TokenERC20(tokenAddr).freezeAccount(target,freeze);
        }
        
    }

    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public {
        if(vSetPrices == 0){
            require(msg.sender == contractAddr);
            vSetPrices = 1;
        } else if(vSetPrices == 1){
            require(msg.sender == silkAddr);
            vSetPrices = 0;
            TokenERC20(tokenAddr).setPrices(newSellPrice, newBuyPrice);
        }
        
    }
    
    function transferOwnershipC(address newOwner) onlyOwner public {
        TokenERC20(tokenAddr).transferOwnership(newOwner);
    }
}
