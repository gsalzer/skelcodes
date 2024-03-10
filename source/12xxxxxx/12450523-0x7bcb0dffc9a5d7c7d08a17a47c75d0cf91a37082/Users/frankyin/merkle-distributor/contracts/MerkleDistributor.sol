// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IMerkleDistributor.sol";
import "./merkle/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MerkleDistributor is IMerkleDistributor, Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    address public override token;
    bytes32 public override merkleRoot;
    uint256 public expiry;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    function initialize(address token_, bytes32 merkleRoot_, uint256 expiry_) public initializer {
        require(token_ != address(0x0), "token not set");
        require(merkleRoot_ != bytes32(0x0), "merkleRoot not set");
        require(expiry_ != uint256(0x0), "expiry not set");
        __Ownable_init();

        token = token_;
        merkleRoot = merkleRoot_;
        expiry = expiry_;
    }

    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external override {
        require(!isClaimed(index), 'MerkleDistributor: Drop already claimed.');
        require(block.timestamp < expiry, "Claim expired.");
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), 'MerkleDistributor: Invalid proof.');

        // Mark it claimed and send the token.
        _setClaimed(index);
        IERC20Upgradeable(token).safeTransfer(account, amount);

        emit Claimed(index, account, amount, expiry);
    }

    function withdraw(address account, uint256 amount) external onlyOwner {
      require(block.timestamp > expiry, "not expired");
      IERC20Upgradeable(token).safeTransfer(account, amount);
    }
}

