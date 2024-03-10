// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155MaxSupplyTradable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title ComethArt
 * ComethArt
 */
contract ComethArt is ERC1155MaxSupplyTradable {
    using SafeMath for uint256;

    constructor()
        ERC1155MaxSupplyTradable(
            "Cometh Art",
            "COMART",
            "https://art.service.cometh.io/{id}"
        )
    {}
}

