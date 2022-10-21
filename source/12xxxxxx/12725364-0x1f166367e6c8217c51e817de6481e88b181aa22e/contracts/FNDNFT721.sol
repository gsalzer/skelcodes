/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "./mixins/OZ/ERC721Upgradeable.sol";

import "./mixins/FoundationTreasuryNode.sol";
import "./mixins/roles/FoundationAdminRole.sol";
import "./mixins/roles/FoundationOperatorRole.sol";
import "./mixins/HasSecondarySaleFees.sol";
import "./mixins/NFT721Core.sol";
import "./mixins/NFT721Market.sol";
import "./mixins/NFT721Creator.sol";
import "./mixins/NFT721Metadata.sol";
import "./mixins/NFT721Mint.sol";
import "./mixins/AccountMigration.sol";

/**
 * @title Foundation NFTs implemented using the ERC-721 standard.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract FNDNFT721 is
  FoundationTreasuryNode,
  FoundationAdminRole,
  FoundationOperatorRole,
  AccountMigration,
  ERC165Upgradeable,
  HasSecondarySaleFees,
  ERC721Upgradeable,
  NFT721Core,
  NFT721Creator,
  NFT721Market,
  NFT721Metadata,
  NFT721Mint
{
  /**
   * @notice Called once to configure the contract after the initial deployment.
   * @dev This farms the initialize call out to inherited contracts as needed.
   */
  function initialize(
    address payable treasury,
    string memory name,
    string memory symbol
  ) public initializer {
    FoundationTreasuryNode._initializeFoundationTreasuryNode(treasury);

    ERC721Upgradeable.__ERC721_init(name, symbol);
    HasSecondarySaleFees._initializeHasSecondarySaleFees();
    NFT721Creator._initializeNFT721Creator();
    NFT721Mint._initializeNFT721Mint();
  }

  /**
   * @notice Allows a Foundation admin to update NFT config variables.
   * @dev This must be called right after the initial call to `initialize`.
   */
  function adminUpdateConfig(address _nftMarket, string memory baseURI) public onlyFoundationAdmin {
    _updateNFTMarket(_nftMarket);
    _updateBaseURI(baseURI);
  }

  /**
   * @dev This is a no-op, just an explicit override to address compile errors due to inheritance.
   */
  function _burn(uint256 tokenId)
    internal
    virtual
    override(ERC721Upgradeable, NFT721Creator, NFT721Metadata, NFT721Mint)
  {
    super._burn(tokenId);
  }
}

