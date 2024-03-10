pragma solidity ^0.6.4;

/**
 * @title AucReceiverInterface
 * @dev Contract interface to receive Auc through an EIP 223 transfer.
 */
interface AucReceiverInterface {
	function tokenFallback(address from, uint256 amount, bytes calldata data) external;
}
