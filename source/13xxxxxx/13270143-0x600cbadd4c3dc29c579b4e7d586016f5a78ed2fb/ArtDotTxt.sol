// SPDX-License-Identifier: MIT
// https://t3rm.dev
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
import './Base64.sol';

contract ArtDotTxt is ERC721Enumerable, Ownable {
  /**
   * Token IDs counter.
   *
   * Provides an auto-incremented ID for each token minted.
   */
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;

  /**
   * Artwork size
   *
   * Type for the t3rm.dev canvas size. (max: 64x64)
   */
  struct Size {
    uint cols;
    uint rows;
  }

  /**
   * Max supply
   *
   * Defines the maximum collection size.
   */
  uint constant _totalSupplyMax = 10000;

  /**
   * Contract URI
   *
   * Defines the contract metadata URI.
   */
  string private _contractURI;

  /**
   * Artwork
   *
   * Token artwork data mapping.
   */
  mapping (uint => string[]) private _art;

  /**
   * Art hash mapping
   *
   * Mapping of artwork hash to tokenID.
   */
   mapping(bytes32 => uint) private _artHash;

  /**
   * Artist mapping
   *
   * Mapping of tokenID to artist.
   */
   mapping(uint => address) private _artists;

  /**
   * Artwork size
   *
   * Token artwork size mapping.
   */
   mapping (uint => Size) private _size;

  /**
   * Whoami contract address
   *
   * Defines the contract address for whoami identities.
   */
  address private _whoamiAddress;

  /**
   * T3rm contract address
   *
   * Defines the contract address for t3rm packages.
   */
  address private _t3rmAddress;

  function _slice(bytes memory _bytes, uint256 _start, uint256 _length) private pure returns (bytes memory) {
    require(_length + 31 >= _length && _bytes.length >= _start + _length);

    bytes memory tempBytes;

    assembly {
      switch iszero(_length)
      case 0 {
        tempBytes := mload(0x40)
        let lengthmod := and(_length, 31)
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      default {
        tempBytes := mload(0x40)
        mstore(tempBytes, 0)
        mstore(0x40, add(tempBytes, 0x20))
      }
    }

    return tempBytes;
  }

  function _concat(bytes memory _preBytes, bytes memory _postBytes) private pure returns (bytes memory) {
    bytes memory tempBytes;

    assembly {
      tempBytes := mload(0x40)

      let length := mload(_preBytes)
      mstore(tempBytes, length)

      let mc := add(tempBytes, 0x20)
      let end := add(mc, length)

      for {
        let cc := add(_preBytes, 0x20)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }

      length := mload(_postBytes)
      mstore(tempBytes, add(length, mload(tempBytes)))

      mc := end
      end := add(mc, length)

      for {
        let cc := add(_postBytes, 0x20)
      } lt(mc, end) {
        mc := add(mc, 0x20)
        cc := add(cc, 0x20)
      } {
        mstore(mc, mload(cc))
      }
      mstore(0x40, and(
        add(add(end, iszero(add(length, mload(_preBytes)))), 31),
        not(31)
      ))
    }

    return tempBytes;
  }

  function _strReplace(string memory _str, string[] memory _find, string[] memory _replace) public pure returns (string memory) {
    uint[64] memory findIdx;
    uint[64] memory replaceIdx;
    uint l = 0;
    bytes memory _s = bytes(_str);
    for (uint i = 0; i < _s.length; i++) {
      bytes1 c = _s[i];
      for (uint j = 0; j < _find.length; j++) {
        bytes1 f = bytes(_find[j])[0];
        if (c == f) {
          findIdx[l] = i;
          replaceIdx[l] = j;
          l++;
          break;
        }
      }
    }
    if (l == 0) return _str;

    bytes memory out;
    uint start = 0;
    for (uint i = 0; i < l; i++) {
      uint end = findIdx[i];
      out = _concat(out, _slice(_s, start, end-start));
      out = _concat(out, bytes(_replace[replaceIdx[i]]));
      start = end + 1;
    }
    out = _concat(out, _slice(_s, start, _s.length - start));

    return string(out);
  }

  /**
   * Get the raw text.
   *
   * Returns the raw text artwork.
   */
  function _escape(string memory _line) private pure returns (string memory) {
    if (bytes(_line).length == 0) return "";

    string[] memory find = new string[](5);
    find[0] = "&";
    find[1] = "<";
    find[2] = ">";
    find[3] = "'";
    find[4] = "\"";

    string[] memory replace = new string[](5);
    replace[0] = '&amp;';
    replace[1] = '&lt;';
    replace[2] = '&gt;';
    replace[3] = '&apos;';
    replace[4] = '&quot;';

    return _strReplace(_line, find, replace);
  }

  /**
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory __contractURI,
    address __whoamiAddress,
    address __t3rmAddress
  ) ERC721(_name, _symbol) {
    _contractURI = __contractURI;
    _whoamiAddress = __whoamiAddress;
    _t3rmAddress = __t3rmAddress;
  }

  /**
   * Contract metadata URI
   *
   * Provides the URI for the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked('ipfs://', _contractURI));
  }

  /**
   * Get the current mint fee.
   *
   * Returns the current transfer amount required to mint
   * a new token.
   */
  function mintFee() public view returns (uint) {
    IERC721 whoami = IERC721(_whoamiAddress);
    IERC721 t3rm = IERC721(_t3rmAddress);
    bool supporter = t3rm.balanceOf(msg.sender) > 0 || whoami.balanceOf(msg.sender) > 0;
    if (supporter && _tokenIDs.current() < 1000) return 0;
    if (_tokenIDs.current() < 2000) return 0.3 ether;
    if (_tokenIDs.current() < 4000) return 0.6 ether;
    if (_tokenIDs.current() < 8000) return 0.8 ether;
    if (_tokenIDs.current() < 9000) return 1.6 ether;
    if (_tokenIDs.current() < 9500) return 2.4 ether;
    if (_tokenIDs.current() < 9997) return 4.8 ether;

    return 100 ether;
  }

  /**
   * Get the artist of a token.
   *
   * Returns the creator of a unique txt-based artwork.
   */
  function getArtist(uint _tokenID) public view returns (address) {
    require(_tokenID > 0 && _tokenID <= _tokenIDs.current(), "Token doesn't exist.");

    return _artists[_tokenID];
  }


  /**
   * Get the maximum token supply.
   *
   * Returns the upper bound on the collection size.
   */
  function totalSupplyMax() public pure returns (uint) {
    return _totalSupplyMax;
  }

  /**
   * Get the raw text.
   *
   * Returns the raw text artwork.
   */
  function rawText(uint256 id) public view returns (string memory) {
    string memory out;
    for (uint i = 0; i < _art[id].length; i++) {
      out = string(abi.encodePacked(out, _art[id][i], i < _art[id].length - 1 ? "\n" : ""));
    }
    return out;
  }

  /**
   * Token URI
   * Returns a base-64 encoded SVG.
   */
  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    Size memory size = _size[tokenId];
    string memory out = string(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" preserveAspectRatio="xMidYMid meet" viewBox="0 0 ',
        Strings.toString(size.cols * 72 / 10 + 45),
        ' ',
        Strings.toString(size.rows * 15 + 45),
        '" style="background-color:#000;fill:#fff;font-family:\'Courier New\',monospace;font-size:12px;font-weight:700"><style>text {white-space: pre}</style>'
        )
      );
    for (uint i = 0; i < _art[tokenId].length; i++) {
      out = string(abi.encodePacked(out, string(abi.encodePacked('<text x="24" y="', Strings.toString(i*15 + 30), '">', _escape(_art[tokenId][i]), '</text>'))));
    }

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name":"Art.txt #', Strings.toString(tokenId), '","description":"A collection of 10,000 unique text-based artworks from https://t3rm.dev command: ART - All text is stored & rendered 100% on-chain.","attributes":[{"trait_type":"rows","value":', Strings.toString(size.rows), '},{"trait_type":"cols","value":', Strings.toString(size.cols),'}', tokenId > 9997 ? ',{"value":"Limited Edition"}' : '' ,'],"image":"data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(out, '</svg>')), '"}'))));
    out = string(abi.encodePacked('data:application/json;base64,', json));

    return out;
  }

  /**
   * Mint a token to an address.
   *
   * Requires payment of _mintFee.
   */
  function mintTo(string[] memory art, address receiver) public payable returns (uint) {
    require(_tokenIDs.current() + 1 <= _totalSupplyMax, "Total supply reached.");

    uint fee = mintFee();
    if (fee > 0) {
      require(msg.value >= fee, "Requires minimum fee.");
      payable(owner()).transfer(msg.value);
    }

    bytes32 artHash = keccak256(abi.encode(art));

    require(_artHash[artHash] == 0, "Artwork exists.");
    require(art.length > 0 && art.length <= 64, "Height range 0-64 chars.");

    uint w = 0;
    uint h = 0;

    for (uint i = 0; i < art.length; i++) {
      bytes memory line = bytes(art[i]);
      if (line.length > 0) h = i+1;
      if (line.length > w) w = line.length;

      for (uint j; j < line.length; j++){
        bytes1 char = line[j];

        require (char >= 0x20 && char <= 0x7E, "Only ASCII chars supported.");
      }
    }

    require(w > 0 && w <= 64, "Width range 0-64 chars.");

    _tokenIDs.increment();
    uint tokenId = _tokenIDs.current();
    _mint(receiver, tokenId);
    _art[tokenId] = art;
    _size[tokenId] = Size(w, h);
    _artists[tokenId] = msg.sender;
    _artHash[artHash] = tokenId;

    return tokenId;
  }

  /**
   * Mint a token to the sender.
   *
   * Requires payment of _mintFee.
   */
  function mint(string[] memory art) public payable returns (uint) {
    return mintTo(art, msg.sender);
  }
}

