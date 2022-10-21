// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./IERC1155.sol";

interface IERC1155_EXT is IERC1155 {
    //function mint(address to, uint256 value, bytes memory data) external;
    function mint(
        address to,
        uint256 value,
        string calldata _hash,
        bytes memory data
    ) external;

    function mintBatch(
        address to,
        uint256[] memory values,
        string[] memory _hash,
        bytes memory data
    ) external;

    function getHashFromTokenID(uint256 tokenId)
        external
        view
        returns (string memory);

    function getTokenIdFromHash(string memory) external view returns (uint256);

    function ownerOf(address owner, uint256 id) external view returns (bool);

    function getTokenAmount(address owner) external view returns (uint256);

    function getAllTokenIds(address owner)
        external
        view
        returns (uint256[] memory);
}

