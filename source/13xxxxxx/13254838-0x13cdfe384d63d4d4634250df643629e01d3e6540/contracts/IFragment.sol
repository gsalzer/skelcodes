/* SPDX-License-Identifier: BUSL-1.1 */
/* Copyright © 2021 Fragcolor Pte. Ltd. */

pragma solidity ^0.8.7;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IFragment is IERC721 {
    function getUtilityLibrary() external view returns (address addr);

    function getController() external view returns (address addr);

    function owner() external view returns (address);
}

