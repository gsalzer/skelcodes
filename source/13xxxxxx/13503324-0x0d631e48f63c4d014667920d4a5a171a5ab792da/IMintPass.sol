// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @author Roi Di Segni (aka @sheeeev66)
 */

import "./IERC721.sol";

interface IMintPass is IERC721 {
    function _burnMintPass(address _address) external;
}
