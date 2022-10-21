// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Consumer is ERC721, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Public variables

    uint256 public constant MAX_NFT_SUPPLY = 3000;
    uint256 public constant MAX_MINT_AMOUNT_AT_ONCE = 15;
    uint256 private mintIndex = 0;

    bool public isMetadataSet = false;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory __name, string memory __symbol)
        ERC721(__name, __symbol)
    {}

    function setMetadata(string memory _uri) external onlyOwner {
        require(isMetadataSet == false, "Metadata is already set");
        _setBaseURI(_uri);
        isMetadataSet = true;
    }

    function getNFTPrice() public view returns (uint256) {
        uint256 currentSupply = totalSupply();
        require(currentSupply <= MAX_NFT_SUPPLY, "Sale has already ended");

        if (currentSupply >= 2500) {
            return 0.7 ether;
        } else if (currentSupply >= 2000) {
            return 0.6 ether;
        } else if (currentSupply >= 1500) {
            return 0.5 ether;
        } else if (currentSupply >= 1000) {
            return 0.4 ether;
        } else if (currentSupply >= 500) {
            return 0.3 ether;
        } else {
            return 0.15 ether;
        }
    }

    /**
     * @dev Mints Masks
     */
    function mintNFT(uint256 numberOfNfts) external payable {
        require(totalSupply() < MAX_NFT_SUPPLY, "Sale has already ended");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(
            numberOfNfts <= MAX_MINT_AMOUNT_AT_ONCE,
            "You can't mint more than maximum amount limit"
        );
        require(
            totalSupply().add(numberOfNfts) <= MAX_NFT_SUPPLY,
            "Exceeds MAX_NFT_SUPPLY"
        );
        require(
            getNFTPrice().mul(numberOfNfts) == msg.value,
            "Ether value sent is not correct"
        );

        for (uint256 i = 0; i < numberOfNfts; i++) {
            mintIndex++;
            _mint(msg.sender, mintIndex);
        }
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
    }
}

