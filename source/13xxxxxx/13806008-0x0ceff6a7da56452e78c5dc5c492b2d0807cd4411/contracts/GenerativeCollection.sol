// contracts/GenerativeCollection.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

interface PresaleContract721Interface {
  function balanceOf(address owner) external view returns (uint256 balance);
}

interface PresaleContract1155Interface {
  function balanceOf(address _owner, uint256 _id)
    external
    view
    returns (uint256);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external
    view
    returns (uint256[] memory);
}

error NotEnoughEther(uint256 requiredEtherAmount);
error ExceededMaxSupply(uint256 maxSupply);
error ExceededMaxPurchaseable(uint256 maxPurchaseable);

contract GenerativeCollection is
  ERC721,
  ERC721Enumerable,
  ERC721URIStorage,
  ERC721Burnable,
  ReentrancyGuard,
  Pausable,
  Ownable
{
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  string _metadataBaseURI;

  uint256 public constant MAX_SUPPLY = 9999;
  uint256 public constant MAX_NFT_PURCHASEABLE = 20;

  uint256 private _reserved = 250;
  uint256 private _mintPrice = 0.025 ether;

  bool private _isPresale = true;

  struct PresaleContract {
    address contractAddress;
    uint256[] tokenIds;
  }
  PresaleContract[] private _presaleContracts;

  constructor() ERC721('BITDAWGS', 'BITDAWGS') {
    _metadataBaseURI = '/';

    addPresaleContract(
      0x8A91221b094c428Eac0462174B05B51d5A3AA869,
      new uint256[](0)
    );

    // increment so first minted ID is 1
    _tokenIdCounter.increment();

    pause();
  }

  modifier whenPresale(address sender) {
    if (_isPresale) {
      bool isEligible = false;
      for (uint256 i = 0; i < _presaleContracts.length; i++) {
        if (
          // ERC721 presale
          _presaleContracts[i].tokenIds.length == 0 &&
          PresaleContract721Interface(_presaleContracts[i].contractAddress)
            .balanceOf(sender) >
          0
        ) {
          isEligible = true;
          break;
        } else if (_presaleContracts[i].tokenIds.length > 0) {
          // ERC1155

          // compile the array of addresses for the batch call
          address[] memory addresses = new address[](
            _presaleContracts[i].tokenIds.length
          );
          for (uint256 j = 0; j < addresses.length; j++) {
            addresses[j] = sender;
          }

          // check balances of tokens for user
          uint256[] memory balances = PresaleContract1155Interface(
            _presaleContracts[i].contractAddress
          ).balanceOfBatch(addresses, _presaleContracts[i].tokenIds);

          for (uint256 k = 0; k < balances.length; k++) {
            if (balances[k] > 0) {
              isEligible = true;
              break;
            }
          }
        }
      }

      require(isEligible, 'Not eligible for pre-sale');
    }

    _;
  }

  modifier whenAmountIsZero(uint256 numberOfTokens) {
    require(numberOfTokens != 0, 'Mint amount cannot be zero');

    _;
  }

  modifier whenNotExceedMaxPurchaseable(uint256 numberOfTokens) {
    if (numberOfTokens < 0 || numberOfTokens > MAX_NFT_PURCHASEABLE) {
      revert ExceededMaxPurchaseable({ maxPurchaseable: MAX_NFT_PURCHASEABLE });
    }

    _;
  }

  modifier whenNotExceedMaxSupply(uint256 numberOfTokens) {
    if (totalSupply() + numberOfTokens > (MAX_SUPPLY - _reserved)) {
      revert ExceededMaxSupply({ maxSupply: (MAX_SUPPLY) });
    }

    _;
  }

  modifier hasEnoughEther(uint256 numberOfTokens) {
    if (msg.value < _mintPrice * numberOfTokens) {
      revert NotEnoughEther({
        requiredEtherAmount: _mintPrice * numberOfTokens
      });
    }

    _;
  }

  function mintNft(uint256 numberOfTokens)
    public
    payable
    nonReentrant
    whenPresale(msg.sender)
    whenNotPaused
    whenAmountIsZero(numberOfTokens)
    whenNotExceedMaxPurchaseable(numberOfTokens)
    whenNotExceedMaxSupply(numberOfTokens)
    hasEnoughEther(numberOfTokens)
  {
    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }
  }

  function giveAwayNft(address to, uint256 numberOfTokens)
    public
    nonReentrant
    onlyOwner
  {
    require(numberOfTokens <= _reserved, 'Exceeds reserved supply');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      if (totalSupply() < MAX_SUPPLY) {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
      }
    }

    _reserved -= numberOfTokens;
  }

  function endPresale() public onlyOwner {
    require(_isPresale);
    _isPresale = false;
  }

  function isPresale() public view virtual returns (bool) {
    return _isPresale;
  }

  function addPresaleContract(
    address contractAddress,
    uint256[] memory tokenIds
  ) public onlyOwner {
    _presaleContracts.push(
      PresaleContract({ contractAddress: contractAddress, tokenIds: tokenIds })
    );
  }

  function clearPresaleContracts() public onlyOwner {
    // reset the presale contracts array
    delete _presaleContracts;
  }

  function getPresaleContracts()
    public
    view
    returns (PresaleContract[] memory)
  {
    return _presaleContracts;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);

    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokenIds;
  }

  function getMintPrice() public view returns (uint256) {
    return _mintPrice;
  }

  function setMintPrice(uint256 newPrice) public onlyOwner {
    _mintPrice = newPrice;
  }

  function _baseURI() internal view override returns (string memory) {
    return _metadataBaseURI;
  }

  function baseURI() public view virtual returns (string memory) {
    return _baseURI();
  }

  function setBaseURI(string memory baseUri) public onlyOwner {
    _metadataBaseURI = baseUri;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    // This forwards all available gas. Be sure to check the return value!
    (bool success, ) = msg.sender.call{ value: balance }('');

    require(success, 'Transfer failed.');
  }

  receive() external payable {}
}

