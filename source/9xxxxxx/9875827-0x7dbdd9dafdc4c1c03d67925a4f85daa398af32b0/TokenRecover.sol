
pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./Context.sol";
import "./RecoverRole.sol";

contract TokenRecover is Context, RecoverRole {

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public onlyRecoverer {
        IERC20(tokenAddress).transfer(_msgSender(), tokenAmount);
    }
}
