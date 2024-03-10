// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {POE} from "./PoE.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

/**
* @title PoExtended
* @author Carson Case [carsonpcase@gmail.com]
* @notice PoExtended is a POE token with owner delegated minters and a merkle claim system
*/
abstract contract PoExtended is POE, Ownable{
    using MerkleProof for bytes32[];
    /// @dev the merkle root which CAN be updated
    address public merkleRoot;

    mapping(address => bool) approved_minters;

    constructor(string memory name_, string memory symbol_) POE(name_,symbol_){}

    /// @dev some functions only callable by approved minters
    modifier onlyMinter(){
        require(approved_minters[msg.sender], "must be approved by owner to call this function");
        _;
    }

    // Begin merkle root functions...

    /// @dev function for owner to update merkle root
    function updateMerkleRoot(address _new) external onlyMinter{
        merkleRoot = _new;
    }

    /// @dev claim function. Any user can claim (and mint) with a verified merkle proof
    function claim(bytes32[] memory proof) external{
        bytes32 root = bytes20(merkleRoot) << 12;
        bytes32 leaf = bytes20(msg.sender) << 12;
        require(proof.verify(root,leaf), "Address not eligible for claim");
        _mint(msg.sender);
    }

    /// @dev only owner can add minters
    function addMinter(address _minter) external onlyOwner{
        require(approved_minters[_minter] != true, "Minter is already approved");
        approved_minters[_minter] = true;
    }

    /// @dev owner can remove them too
    function removeMinter(address _minter) external onlyOwner{
        require(approved_minters[_minter] != false, "Minter is already not-approved");
        approved_minters[_minter] = false;
    }

    /// @dev A minter can forefit their minting status (useful for contracts)
    function forefitMinterRole()external{
        require(approved_minters[msg.sender] == true, "msg.sender must be an approved minter");
        approved_minters[msg.sender] = false;
    }

    /**
     * @dev Mints 1 POE token to the given address.
     */
    function mint(address account) external onlyMinter returns (bool) {
        _mint(account);
        return true;
    }
    
    /**
     * @dev Burns 1 POE token from the given address.
     */
    function burn(address account) external onlyOwner returns (bool) {
        _burn(account, balanceOf(account));
        return true;
    }
    
    /**
     * @dev Batch mint POE tokens to multiple addresses.
     */
    function mintMany(address[] memory accounts) external onlyMinter returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i]);
        }
        
        return true;
    }
    
    /** 
     * @dev Batch burn POE tokens from multiple addresses.
     */
    function burnMany(address[] memory accounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _burn(accounts[i], balanceOf(accounts[i]));
        }
        
        return true;
    }


}

