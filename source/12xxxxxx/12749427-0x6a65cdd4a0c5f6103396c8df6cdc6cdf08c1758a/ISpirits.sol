pragma solidity ^0.7.0;

import "./IERC721Enumerable.sol";

interface ISpirits is IERC721Enumerable {
    
    function revealStageByIndex(uint256 index) external view returns (uint256);
    function mintedTimestampByIndex(uint256 index) external view returns (uint256);
    
    function nodeInfo(uint256 nodeId) external view returns (address, string memory, uint256, uint256, uint256, bool, uint256[] memory);
    function nodeBalanceOf(address owner) external view returns (uint256);
    function ownerOfNode(uint256 nodeId) external view returns (address);
    function nodeOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalNodes() external view returns (uint256);
    function totalActiveNodes() external view returns (uint256);
    function nodeType(uint256 nodeId) external view returns (uint256);
    function nodeSize(uint256 nodeId) external view returns (uint256);
    function nodeValid(uint256 nodeId) external view returns (bool);
    function nodeRegTime(uint256 nodeId) external view returns (uint256);
    function nodeUnregTime(uint256 nodeId) external view returns (uint256);
    function nodeName(uint256 nodeId) external view returns (string memory);
    function nodeActive(uint256 nodeId) external view returns (bool);
    function nodeTokenIds(uint256 nodeId) external view returns (uint256[] memory);
    function isNodeNameReserved(string memory nameString) external view returns (bool);
    function nodeIdFromTokenId(uint256 tokenId) external view returns (uint256);
    function nodeExists(uint256 nodeId) external view returns (bool);
    function isUserNameReserved(string memory nameString) external view returns (bool);
    function username(address owner) external view returns (string memory);
    function tokenRewardMultiplier(uint256 tokenId) external view returns (uint256, uint256);
    function testTokenRewardMultiplier(uint256 newNum, uint256 newDen) external pure returns (uint256);
}
