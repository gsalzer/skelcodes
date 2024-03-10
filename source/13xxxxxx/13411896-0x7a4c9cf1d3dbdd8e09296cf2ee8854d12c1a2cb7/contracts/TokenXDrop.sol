// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface ERC20Mint {
    function mint(address to, uint256 amount) external;
}

contract Drop {
    using MerkleProof for bytes;

    event DropClaimed(
        address indexed tokenAddress,
        uint256 index,
        address indexed account,
        uint256 amount,
        bytes32 indexed merkleRoot
    );

    struct DropData {
        uint256 startDate;
        uint256 endDate;
        uint256 tokenAmount;
        address owner;
        bool isActive;
    }

    mapping(uint256 => uint256) private claimedBitMap;
    DropData public dropData;
    bytes32 public merkleRoot;
    address public token;
    address public multisig;

    constructor(
        bytes32 _merkleRoot,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _tokenAmount,
        address _tokenAddress,
        address _multisig
    ) {
        token = _tokenAddress;
        merkleRoot = _merkleRoot;
        dropData = DropData(_startDate, _endDate, _tokenAmount, msg.sender, true);
        multisig = _multisig;
    }

    function withdrawUnclaimed() external {
        require(block.timestamp > dropData.endDate, "NOT_FINISHED");
        ERC20Mint(token).mint(multisig, dropData.tokenAmount);
    }

    function claimFromDrop(
        address, /*tokenAddress*/
        uint256 index,
        uint256 amount,
        bytes32, /*merkleRoot*/
        bytes32[] calldata merkleProof
    ) external {
        bytes32 _merkleRoot = merkleRoot;
        address account = msg.sender;

        claim(index, account, amount, _merkleRoot, merkleProof);

        emit DropClaimed(token, index, account, amount, _merkleRoot);
    }

    function multipleClaimsFromDrop(
        address, /*tokenAddress*/
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[] calldata, /*merkleRoots*/
        bytes32[][] calldata merkleProofs
    ) external {
        address account = msg.sender;
        bytes32 _merkleRoot = merkleRoot;
        address _token = token;

        for (uint256 i = 0; i < indexes.length; i++) {
            claim(indexes[i], account, amounts[i], _merkleRoot, merkleProofs[i]);

            emit DropClaimed(_token, indexes[i], account, amounts[i], _merkleRoot);
        }
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32 _merkleRoot,
        bytes32[] calldata merkleProof
    ) internal {
        DropData memory dd = dropData;

        require(dd.startDate < block.timestamp, "DROP_NOT_STARTED");
        require(dd.endDate > block.timestamp, "DROP_ENDED");
        require(dd.isActive, "DROP_NOT_ACTIVE");
        require(!isClaimed(index), "DROP_ALREADY_CLAIMED");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, _merkleRoot, node), "DROP_INVALID_PROOF");

        // Subtract from the drop amount
        dropData.tokenAmount -= amount;

        // Mark it claimed and send the tokens.
        _setClaimed(index);
        ERC20Mint(token).mint(account, amount);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function pause() external {
        require(dropData.owner == msg.sender, "NOT_OWNER");
        dropData.isActive = false;
    }

    function unpause() external {
        require(dropData.owner == msg.sender, "NOT_OWNER");
        dropData.isActive = true;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }
}

