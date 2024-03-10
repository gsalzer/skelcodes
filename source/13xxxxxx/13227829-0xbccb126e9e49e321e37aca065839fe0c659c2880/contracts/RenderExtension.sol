//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IRenderExtension.sol";

abstract contract RenderExtension is IRenderExtension {
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165) returns (bool) {
        return interfaceId == type(IRenderExtension).interfaceId;
    }
}

