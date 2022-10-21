// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./util/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// erc20 token staking based PASS contract. User stake erc20 tokens to mint PASS and burn PASS to get erc20 tokens back.
contract TokenBase is
  Initializable,
  ContextUpgradeable,
  OwnableUpgradeable,
  ERC721Upgradeable,
  ERC721BurnableUpgradeable
{
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  event Mint(address indexed from, uint256 indexed tokenId);
  event Burn(address indexed from, uint256 indexed tokenId);
  event SetBaseURI(string baseURI_);
  event PermanentURI(string _value, uint256 indexed _id);
  event BaseURIFrozen();

  bool public baseURIFrozen;
  address public erc20; // staked erc20 token address
  uint256 public rate; // staking rate of erc20 tokens/PASS

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseURIextended;

  // token id counter. For erc721 contract, PASS index number = token id
  CountersUpgradeable.Counter private tokenIdTracker;

  function initialize(
    string memory _name,
    string memory _symbol,
    string memory _bURI,
    address _timelock,
    address _erc20,
    uint256 _rate
  ) public virtual initializer {
    __Ownable_init(_timelock);
    __ERC721_init(_name, _symbol);
    __ERC721Burnable_init();

    tokenIdTracker = CountersUpgradeable.Counter({_value: 1});

    _baseURIextended = _bURI;
    erc20 = _erc20;
    rate = _rate;
  }

  // only contract admin can setTokenURI
  function setBaseURI(string memory baseURI_) public onlyOwner {
    require(!baseURIFrozen, "baseURI has been frozen");
    _baseURIextended = baseURI_;
    emit SetBaseURI(baseURI_);
  }

  // only contract admin can freeze Base URI
  function freezeBaseURI() public onlyOwner {
    require(!baseURIFrozen, "baseURI has been frozen");
    baseURIFrozen = true;
    emit BaseURIFrozen();
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIextended;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory _tokenURI = _tokenURIs[tokenId];

    // If token URI exists, return the token URI.
    if (bytes(_tokenURI).length > 0) {
      return _tokenURI;
    } else {
      return super.tokenURI(tokenId);
    }
  }

  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    require(_exists(tokenId), "URI set of nonexistent token");

    string memory tokenURI_ = _tokenURIs[tokenId];
    require(bytes(tokenURI_).length == 0, "already set TokenURI");

    _tokenURIs[tokenId] = _tokenURI;
    emit PermanentURI(_tokenURI, tokenId);
  }

  // only contract admin can setTokenURI
  function setTokenURI(uint256 tokenId, string memory _tokenURI)
    public
    onlyOwner
  {
    _setTokenURI(tokenId, _tokenURI);
  }

  // stake erc20 tokens to mint PASS
  function mint() public returns (uint256 tokenId) {
    tokenId = tokenIdTracker.current(); // accumulate the token id

    IERC20Upgradeable(erc20).safeTransferFrom(
      _msgSender(),
      address(this),
      rate
    );

    _safeMint(_msgSender(), tokenId); // mint PASS to user address
    emit Mint(_msgSender(), tokenId);

    tokenIdTracker.increment(); // automate token id increment
  }

  // burn PASS to get erc20 tokens back
  function burn(uint256 tokenId) public virtual override {
    super.burn(tokenId);
    IERC20Upgradeable(erc20).safeTransfer(_msgSender(), rate);

    emit Burn(_msgSender(), tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

