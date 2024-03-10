// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title GasGiveaway
/// @author jpegmint.xyz

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**______________________________________________________________________________
|   __________________________________________________________________________   |
|  |                                                                          |  |
|  |                                                                          |  |
|  |          __________________________________________                      |  |
|  |         |                 GasGiveaway              |'-._ _______         |  |
|  |         |__________________________________________|    '-.__.-'|        |  |
|  |          '-._                                      '-._         |        |  |
|  |              '-._______________________________________'-.___.-'         |  |
|  |                  | ||      .##.                        | ||              |  |
|  |    "     "     " | || "  ".#  #_________ "  "  ___ "  "| || "   "   "    |  |
|  |      "    "  "  "| ||"  " #  /*_______ /| "   /__/| "  | ||" "    "      |  |
|  |  "     "   "  "  | || "   # | 30 gwei | |"  "|   ||" " | ||   "  "  "    |  |
|  |  ================| ||=====#=|_________|/=====|___|/====| ||============  |  |
|  |                  | ||     #   |     | |       | ||     | ||              |  |
|  |            .-----| ||-----#--f|     | |-------| ||-----| ||----.         |  |
|  |           :      |_|/     '##'|_____|/        |_|/     |_|/     :        |  |
|  |           :___________________________________________________.':        |  |
|  |           '----------------------------------------------------'         |  |
|  |                                                                          |  |
|  |                                                                          |  |
|  |                                                                          |  |
|  |  --------------------------------------------------------------------    |  |
|  |                                                                          |  |
|  |__________________________________________________________________________|  |
|_______________________________________________________________________________*/

contract GasGiveaway is ERC721Holder {

    uint256 public constant LOW_GAS = 30 gwei;

    error GasTooHigh();
    error TokenNotOwned();

    function claim(address contractAddress, uint256 tokenId)
        external
    {
        if (block.basefee > LOW_GAS)
            revert GasTooHigh();

        if (IERC721(contractAddress).ownerOf(tokenId) != address(this))
            revert TokenNotOwned();

        IERC721(contractAddress).transferFrom(address(this), msg.sender, tokenId);
    }
}

