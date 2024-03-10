pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// temporary plan of cross-chain before auto cross-chain available : For ETH to BSC
/// Lock token in contract, then will cross equal amount token to destination chain
/// The locked amount will be transfer to LockContract of Auto-cross-chain to provide cross-chain liquidity
contract SilBridge is  Ownable {

    function transferTo(address _token, address _to) public onlyOwner {
        IERC20(_token).transfer(_to, IERC20(_token).balanceOf(address(this)));
    }
}
