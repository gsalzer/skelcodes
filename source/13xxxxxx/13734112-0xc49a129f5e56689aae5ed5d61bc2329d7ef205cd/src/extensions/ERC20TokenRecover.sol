// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title ERC20TokenRecover
 * @author Henk ter Harmsel
 * @dev Allows owner to recover any ERC20 or ETH sent into the contract
 * based on https://github.com/vittominacori/eth-token-recover by Vittorio Minacori
 */
contract ERC20TokenRecover is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

    constructor(address owner) {
        _grantRole(RECOVER_ROLE, owner);
    }

    /**
     * @notice function that transfers an token amount from this contract to the owner when accidentally sent
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyRole(RECOVER_ROLE) {
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    /**
     * @notice function that transfers an eth amount from this contract to the owner when accidentally sent
     * @param amount Number of eth to be sent
     */
    function recoverETH(uint256 amount) public virtual onlyRole(RECOVER_ROLE) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "ERC20TokenRecover: SENDING_ETHER_FAILED");
    }
}

