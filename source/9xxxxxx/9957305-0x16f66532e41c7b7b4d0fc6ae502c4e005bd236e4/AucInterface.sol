pragma solidity ^0.6.4;

import "EIP20Interface.sol";

/**
 * @title AucInterface
 * @dev Interface for the Auc token.
 * Auc is an ERC 20 token with additional functions.
 * burn - To burn Auc amount.
 * transfer - EIP 223 transfer that calls the tokenFallback on destination contract.
 */
interface AucInterface is EIP20Interface {
    function burn(uint256 amount) external returns(bool);
    function transfer(address dst, uint256 amount, bytes calldata data) external returns(bool);
}
