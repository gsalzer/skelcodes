// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC165} from "../utils/IERC165.sol";


abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

