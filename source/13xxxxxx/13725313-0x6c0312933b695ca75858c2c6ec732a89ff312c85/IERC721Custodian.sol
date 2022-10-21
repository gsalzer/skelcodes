// SPDX-License-Identifier: MIT

// https://kanon.art - K21
// https://daemonica.io
//
//
//                                   $@@@@@@@@@@@$$$
//                               $$@@@@@@$$$$$$$$$$$$$$##
//                           $$$$$$$$$$$$$$$$$#########***
//                        $$$$$$$$$$$$$$$#######**!!!!!!
//                     ##$$$$$$$$$$$$#######****!!!!=========
//                   ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                 *#################*#***!*!!======;;;:::
//                ################********!!!!====;;;:::~~~~~
//              **###########******!!!!!!==;;;;::~~~--,,,-~
//             ***########*#*******!*!!!!====;;;::::~~-,,......,-
//            ******#**********!*!!!!=!===;;::~~~-,........
//           ***************!*!!!!====;;:::~~-,,..........
//         !************!!!!!!===;;::~~--,............
//         !!!*****!!*!!!!!===;;:::~~--,,..........
//        =!!!!!!!!!=!==;;;::~~-,,...........
//        =!!!!!!!!!====;;;;:::~~--,........
//       ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//       ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//       ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//      :;;==========;;;;;;::::~~~--,,....@@$$##*!=;:~-.
//      :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//       :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//       :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//       ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//        ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//         -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//          ---~~~-----,,,,,........,---,.
//           ,,--------,,,,,,.........
//             .,,,,,,,,,,,,......
//                ...............
//                    .........

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC721 NFT Custodian contract interface
 * @author 0xAnimist
 * @notice For binding two NFTs together
 */
interface IERC721Custodian is IERC721 {

  /** @notice Returns the guardian token contract and tokenId for a given source
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    * @return The contract address of the guardian token
    * @return The tokenId of the guardian token
    */
  function getGuardianToken(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external view returns (address, uint256);


  /** @notice Returns the owner address of a guardian token
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    * @return The Ethereum address of the guardian token's owner
    */
  function getGuardianOwner(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external view returns (address);


  /** @notice Returns the message sent by the source NFT owner when they put it
    * into guardianship
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _xe_ntityId The tokenId of a ERC721 source token in guardianship
    * @return The message
    */
  function getBindingMessage(
    address _sourceContract,
    uint256 _xe_ntityId
  ) external view returns (bytes memory);


  /** @notice Binds the source NFT to the guardian NFT, giving the guardian token
    * owner the right to claim it at any time by unbinding
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    * @param _guardianContract The ERC721 guardian contract
    * @param _guardianTokenId The tokenId of a ERC721 guardian token
    */
  function bind(
    address _sourceContract,
    uint256 _sourceTokenId,
    address _guardianContract,
    uint256 _guardianTokenId
  ) external;


  /** @notice Binds the source NFT to the guardian NFT with a message, giving the
    * guardian token owner the right to claim it at any time by unbinding
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    * @param _guardianContract The ERC721 guardian contract
    * @param _guardianTokenId The tokenId of a ERC721 guardian token
    * @param _data The message
    */
  function bind(
    address _sourceContract,
    uint256 _sourceTokenId,
    address _guardianContract,
    uint256 _guardianTokenId,
    bytes memory _data
  ) external;


  /** @notice Unbinds the source NFT from the guardian NFT, giving the guardian
    * token owner the ownership of the source NFT
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    */
  function unbind(
    address _sourceContract,
    uint256 _sourceTokenId
  ) external;


  /** @notice Unbinds the source NFT from the guardian NFT with a message, giving
    * the guardian token owner the ownership of the source NFT
    * @param _sourceContract The ERC721 source contract for a token in guardianship
    * @param _sourceTokenId The tokenId of a ERC721 source token in guardianship
    * @param _data The message
    */
  function unbind(
    address _sourceContract,
    uint256 _sourceTokenId,
    bytes memory _data
  ) external;

}

