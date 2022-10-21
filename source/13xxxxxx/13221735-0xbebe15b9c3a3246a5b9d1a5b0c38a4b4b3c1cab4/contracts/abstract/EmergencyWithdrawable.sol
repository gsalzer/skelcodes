pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract EmergencyWithdrawable is OwnableUpgradeable {
    // for worst case scenarios or to recover funds from people sending to this contract by mistake
    function emergencyWithdrawETH() external payable onlyOwner {
        msg.sender.send(address(this).balance);
    }

    // for worst case scenarios or to recover funds from people sending to this contract by mistake
    function emergencyWithdrawTokens(IERC20Upgradeable token) external onlyOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}

