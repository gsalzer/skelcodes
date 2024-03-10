// SPDX-License-Identifier: Toknify.com
pragma solidity ^0.8.0;
import "./IERC721.sol";
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
