// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @author Roi Di Segni (aka @sheeeev66)
 * inspired by OpenZeppelin Contracts v4.3.2 (finance/PaymentSplitter.sol)
 * In collaboration with "Core Devs"
 */

import './IERC20.sol';
import './IERC721.sol';
import './Ownable.sol';

contract PugApesGratuity is Ownable {

    event GratuityReceived(address from, uint256 amount);
    event GratuityReleased(address to, uint256 amount);

    uint256 totalReleased;
    uint64 pullThreshold;

    IERC721 pugApesContract;

    mapping(address => uint256) private _released;

    receive() external payable virtual {
        emit GratuityReceived(_msgSender(), msg.value);
    }

    /**
     * @dev sets the pull threshold
     */
    function setPullThreshold(uint64 threshold) external {
        pullThreshold = threshold;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total tokens and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(pugApesContract.balanceOf(account) > 0, "Address holds no PugApes!");

        uint gratuity = gratuityAvalibleToRelease(account);

        require(gratuity >= pullThreshold, "Wallet is not due payment!");

        _released[account] += gratuity;
        totalReleased += gratuity;

        require(gratuity >= pullThreshold, "Wallet is not due payment!");

        emit GratuityReleased(account, gratuity);
    }

    /**
     * @dev calculates the avalible gratuity
     */
    function gratuityAvalibleToRelease(address account) public view returns(uint gratuity) {
        uint256 totalReceived = address(this).balance + totalReleased;
        gratuity = (totalReceived * pugApesContract.balanceOf(account)) / 8888 - _released[account];
    }

    /**
     * @dev to be withdrawn by the owner of the contract to trade for eth and deposit back to be splitted
     */
    function withdrawERC20(IERC20 token) public onlyOwner {
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "Transfer Failed!");
    }
}
