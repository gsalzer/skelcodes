pragma solidity 0.5.0;

import "IERC20.sol";
import "IOneSplitMini.sol";

contract OneSplitTest {

address constant oneSplitEth = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
//address public oneSplitProto = 0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e;

//address public fromToken = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
//address public toToken = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;


//IERC20 public fromIERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
//IERC20 public toIERC20 = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
//amount = 1e18
    
    /*
    function testSplit(address OneSplitAddr, address fromToken, address toToken, uint amount) public view returns (uint) {
        
        IERC20 fromIERC20 = IERC20(fromToken);
        IERC20 toIERC20 = IERC20(toToken);

        (uint256 returnAmount0,) = IOneSplit(OneSplitAddr).getExpectedReturn(fromIERC20, toIERC20, amount, 100, 0 );
        
        return returnAmount0;
        
    }*/
    
    function testChange(address fromToken, address toToken, uint amount) external returns (uint) {
        
        IERC20 fromIERC20 = IERC20(fromToken);
        IERC20 toIERC20 = IERC20(toToken);

        IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
        
        (, uint256[] memory distribution) = IOneSplit(oneSplitEth).getExpectedReturn(fromIERC20, toIERC20, amount, 100, 0 );
        
        uint returnAmount = IOneSplit(oneSplitEth).swap(fromIERC20, toIERC20, amount, 0, distribution, 0);
        
        IERC20(toToken).transfer(msg.sender, returnAmount);
        
        return returnAmount;
    }
    
    
    function transferTokenBack(address TokenAddress) external returns (uint256){
        IERC20 Token = IERC20(TokenAddress);
        uint256 balance = Token.balanceOf(address(this));
        bool result = Token.transfer(msg.sender, balance);
        
        if (!result) { 
            balance = 0;
        }
        
        return balance;
    }
    
}
