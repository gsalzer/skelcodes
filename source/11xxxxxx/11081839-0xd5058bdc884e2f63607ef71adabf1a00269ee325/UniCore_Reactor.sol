  
// SPDX-License-Identifier: WHO GIVES A FUCK ANYWAY??
// but thanks a million Gwei to MIT and Zeppelin. You guys rock!!!

// MAINNET VERSION.

pragma solidity ^0.6.6;

import "./UniCore_ERC20.sol";

//Liquidity Token Wrapper

contract wUNIV2 is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    address public UniCore;
    address public UNIv2;


    modifier onlyUniCore() {
        require(msg.sender == UniCore, "Only UniCore can send wrapped tokens");
        _;
    }
//=========================================================================================================================================
    constructor(address _UniCore) ERC20("Wrapped UniCore LP","REACTOR") public {
        UniCore = _UniCore;
        UNIv2 = IUniCore(UniCore).viewUNIv2();
        require(UniCore != address(0) && UNIv2 != address(0));
    }

//=========================================================================================================================================
    //WUNIv2 minter
    function _wrapUNIv2(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        //Get UniCore Balance of UNIv2
        uint256 UNIv2Balance = ERC20(UNIv2).balanceOf(UniCore);
        
        //transferFrom UNIv2
        ERC20(UNIv2).transferFrom(sender, recipient, amount);
        
        //Mint Tokens, equal to the UNIv2 amount sent
        _mint(sender, amount.mul(publicWrappingRatio).div(100));

        //Checks if balances OK otherwise throw
        require(UNIv2Balance.add(amount) == ERC20(UNIv2).balanceOf(UniCore), "Math Broken");
    }
    
    function wTransfer(address recipient, uint256 amount) external onlyUniCore{
        _mint(recipient, amount);
    }
    
    //Allows user to wrap UNIv2 tokens
    uint256 private publicWrappingRatio;
    
    function wrapUNIv2(uint256 amount) public {
        require(publicWrappingRatio > 0, "Post-LGE wrapping of LP tokens not opened");
        _wrapUNIv2(msg.sender, UniCore, amount);
    }
    
    function setPublicWrappingRatio(uint256 _ratioBase100) external onlyUniCore {
        require(_ratioBase100 <= 100, "wrappingRatio capped at 100%");
        publicWrappingRatio = _ratioBase100;
    }
    function viewPublicWrappingRatio() public view returns(uint256)  {
        return publicWrappingRatio;
    }

}

