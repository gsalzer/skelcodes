// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

contract Trader {
    constructor() {}

    function transferFrom(
        address _contract,
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        IERC721 token = IERC721(_contract);
        token.transferFrom(_from, _to, _tokenId);
    }
}

