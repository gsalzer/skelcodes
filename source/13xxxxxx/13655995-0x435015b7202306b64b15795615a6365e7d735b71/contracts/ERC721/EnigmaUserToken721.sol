// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT721.sol";

/// @title EnigmaUserToken721
///
/// @dev This contract extends from BaseEnigmaNFT721

contract EnigmaUserToken721 is BaseEnigmaNFT721 {
    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice public function to mint a new token.
     * @param tokenURI_ string memory URI of the token to be minted.
     * @param fee_ uint256 royalty of the token to be minted.
     */
    function createCollectible(string memory tokenURI_, uint256 fee_) external returns (uint256) {
        uint256 newItemId = tokenCounter;
        tokenCounter = tokenCounter + 1;
        _safeMint(msg.sender, newItemId, fee_);
        _setTokenURI(newItemId, tokenURI_);
        return newItemId;
    }
}

