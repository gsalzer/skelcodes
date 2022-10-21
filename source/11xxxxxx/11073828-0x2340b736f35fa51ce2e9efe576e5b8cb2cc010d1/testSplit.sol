pragma solidity 0.5.0;

import "IERC20.sol";
import "IOneSplit.sol";

contract OneSplitTest {

address public oneSplitEth = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
address public oneSplitProto = 0x50FDA034C0Ce7a8f7EFDAebDA7Aa7cA21CC1267e;

address public fromToken = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
address public toToken = 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;

IERC20 public fromIERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
IERC20 public toIERC20 = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);


    
    function testSplit() public view returns (uint) {
        
        (uint256 returnAmount0,) = IOneSplit(oneSplitEth).getExpectedReturn(fromIERC20, toIERC20, 1e18, 100, 0 );
        
        return returnAmount0;
        
    }
    
    function testProto() public view returns (uint) {
        
        (uint256 returnAmount0,) = IOneSplit(oneSplitProto).getExpectedReturn(fromIERC20, toIERC20, 1e18, 100, 0 );
        
        return returnAmount0;
        
    }
    
}
