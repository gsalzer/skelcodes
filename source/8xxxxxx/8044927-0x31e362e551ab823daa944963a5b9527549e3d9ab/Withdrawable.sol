pragma solidity 0.5.9;

import "./PermissionGroups.sol";
import "./SafeERC20.sol";

/**
 * @title Contracts that should be able to recover tokens or ethers can inherit this contract.
 * @author Ilan Doron
 * @dev Allows to recover any tokens or Ethers received in a contract.
 * Should prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {
    using SafeERC20 for ERC20;
    constructor(address _admin) public PermissionGroups (_admin) {}

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address payable sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

