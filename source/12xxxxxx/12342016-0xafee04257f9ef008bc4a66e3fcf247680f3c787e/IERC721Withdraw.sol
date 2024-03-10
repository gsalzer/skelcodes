pragma solidity ^0.4.23;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC721Withdraw {
    /**
    * @dev Approve or remove `operator` as an operator for the caller.
    * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
    *
    * Requirements:
    *
    * - The `operator` cannot be the caller.
    *
    * Emits an {ApprovalForAll} event.
    */
    function setApprovalForAll(address operator, bool _approved) external;
}

