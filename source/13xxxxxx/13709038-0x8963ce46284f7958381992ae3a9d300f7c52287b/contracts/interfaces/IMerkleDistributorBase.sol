// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC20Mintable.sol";

interface IMerkleDistributorBase is IERC721Metadata, IERC721Enumerable {
    function token() external view returns (IERC20Mintable);
    function distributionCount() external view returns (uint256);
    function merkleRoot() external view returns (bytes32);
    function previousMerkleRoot(bytes32 merkleRoot) external view returns (bool);
    function accountState(address account) external view returns (uint256 totalClaimed, uint256 totalSlashed);
    function claim(uint256 index, address account, uint256 totalEarned, bytes32[] calldata merkleProof) external;
    function slash(address account, uint256 amount) external;
    function addUpdaters(address[] memory newUpdaters, uint256 newThreshold) external;
    function removeUpdaters(address[] memory existingUpdaters, uint256 newThreshold) external;
    function setUpdateThreshold(uint256 to) external;
    event Claimed(uint256 index, uint256 totalEarned, address indexed account, uint256 claimed);
    event Slashed(address indexed account, uint256 slashed);
    event AccountUpdated(address indexed account, uint256 totalClaimed, uint256 totalSlashed);
    event PermanentURI(string value, uint256 indexed id);
    event UpdateThresholdChanged(uint256 updateThreshold);
}

