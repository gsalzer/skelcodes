// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
contract IPermittableERC20 is IERC20 {

    /**
     * @notice Approve token with signature
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;
}

