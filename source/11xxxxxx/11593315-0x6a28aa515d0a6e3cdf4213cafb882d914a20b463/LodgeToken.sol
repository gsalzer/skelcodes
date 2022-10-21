// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { ERC1155 } from "./ERC1155.sol";

abstract contract LodgeToken is ERC1155 {
    constructor(string memory _newuri) internal ERC1155(_newuri) {}

    function setURI(string memory _newuri) external virtual;

}
