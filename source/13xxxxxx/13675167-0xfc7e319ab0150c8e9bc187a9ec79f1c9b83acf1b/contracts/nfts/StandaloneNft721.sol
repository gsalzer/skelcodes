// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IEFMetadataSubContract {
  function uri(uint256 id) external view returns (string memory);
}

contract StandaloneNft721 is ERC721, AccessControl {

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

  uint256 public totalSupply;
  uint256 public nextTokenId = 1;

  bool public isTotalSupplyLocked = false;

  address public contractOwner;
  string public contractURIString;
  string public baseUri;

  mapping (address => uint256) public numberMintedByAddress;

  modifier onlyOwner() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()));
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "not a minter");
    _;
  }

  constructor(string memory _name, string memory _symbol, uint256 _totalSupply, string memory _baseUri, string memory _contractURIString, address _contractOwner) 
    ERC721(_name, _symbol) {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
      _setupRole(DEFAULT_ADMIN_ROLE, _contractOwner);
      baseUri = _baseUri;
      contractOwner = _contractOwner;
      contractURIString = _contractURIString;
      totalSupply = _totalSupply;
  }

  function owner() public view virtual returns (address) {
    return contractOwner;
  }

  function addToNumberMintedByAddress(address _address, uint256 _amount) external onlyMinter {
    numberMintedByAddress[_address] += _amount;
  }

  function setcontractURI(string memory _contractURIString)
    external onlyOwner {
      contractURIString = _contractURIString;
  }

  function setBaseURI(string memory _baseURIString)
    external onlyOwner {
      baseUri = _baseURIString;
  }

  function setTotalSupply(uint256 _totalSupply)
    external onlyOwner {
      require(!isTotalSupplyLocked, 'supply locked');
      totalSupply = _totalSupply;
  }

  function lockTotalSupply()
    external onlyOwner {
      isTotalSupplyLocked = true;
  }

  function mint(address _to, uint256 _tokenId) external onlyMinter {
    require(_tokenId > totalSupply, 'bad id');
    _mint(_to, _tokenId);
  }

  function mintNext(address _to, uint256 _amount) external onlyMinter {
    uint256 _nextTokenId = nextTokenId;
    require(_nextTokenId + _amount <= totalSupply + 1, 'all minted');

    for (uint256 i; i < _amount; i++) {
      _safeMint(_to, _nextTokenId);
      _nextTokenId++;
    }
    nextTokenId = _nextTokenId;
  }

  function burn(uint256 _tokenId) external {
    require(hasRole(BURNER_ROLE, _msgSender()), "not a burner");
    _burn(_tokenId);
  }

  function supportsInterface(bytes4 interfaceId) 
    public virtual override(ERC721, AccessControl) view returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
  }

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseUri, Strings.toString(id)));
  }



  // Mimic 1155 in order to allow to be traded in the market

  function balanceOf(address _owner, uint256 _id) external pure returns (uint256) {
    // always returns 1 for market contract to work, use 'ownerOf' for actual info
    return 1;
  }

  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
    require(_value == 1);
    safeTransferFrom(_from, _to, _id, _data);
  }

  function uri(uint256 id) public view returns (string memory) {
    return tokenURI(id);
  }
}
 
