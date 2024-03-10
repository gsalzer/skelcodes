//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./extensions/ERC721Staked.sol";
import "./IPlotMetadata.sol";
import "./libraries/FormatMetadata.sol";

contract SPlot is ERC721Staked {
  address public metadataAddress;

  function initialize(address _metadataAddress) public initializer {
    __ERC721Staked_init("Staked Plot", "sPLOT");
    metadataAddress = _metadataAddress;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    return
      IPlotMetadata(metadataAddress).getMetadata(
        tokenId,
        true,
        _getAdditionalAttributes(tokenId)
      );
  }

  function _getAdditionalAttributes(uint256 tokenId)
    internal
    view
    returns (string[] memory)
  {
    uint256 lockDuration = getLockDuration(tokenId);
    uint256 lockExpiration = getLease(tokenId).lockExpiration;
    string[] memory additionalAttributes = new string[](
      lockExpiration > 0 ? 2 : 1
    );

    additionalAttributes[0] = FormatMetadata.formatTraitNumber(
      "Lock Duration",
      lockDuration,
      "number"
    );

    if (lockExpiration > 0) {
      additionalAttributes[1] = FormatMetadata.formatTraitNumber(
        "Lock Expiration",
        lockExpiration,
        "date"
      );
    }

    return additionalAttributes;
  }
}

