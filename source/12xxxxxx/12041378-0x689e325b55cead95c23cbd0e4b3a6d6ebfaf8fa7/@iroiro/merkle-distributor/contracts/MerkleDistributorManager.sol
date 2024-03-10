// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/MerkleProof.sol";
import "./interfaces/IMerkleDistributorManager.sol";

contract MerkleDistributorManager is IMerkleDistributorManager {
    function claim(
        uint64 distributionId,
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) virtual external {
        require(!isClaimed(distributionId, index), 'MerkleDistributor: Drop already claimed.');
        Distribution storage dist = distributionMap[distributionId];
        require(amount <= dist.remainingAmount, "MerkleDistributor: Insufficient token.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, dist.merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(distributionId, index);
        dist.remainingAmount = dist.remainingAmount - amount;

        require(IERC20(dist.token).transfer(account, amount), 'MerkleDistributor: Transfer failed.');

        emit Claimed(distributionId, account, amount);
    }
}

