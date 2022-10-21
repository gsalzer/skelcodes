// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract BeesDeluxe is ERC721Enumerable, ERC721Burnable, AccessControlEnumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 20700;
    uint8 public lockedUrlChange = 0;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    mapping(uint16 => string) private customTokenUris;

    event LockedUrl();
    event UrlChanged(uint256 indexed _id, string newUrl);

    constructor() ERC721("Bees Deluxe", "BeesDeluxe") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
    }

    string private baseUri = "https://ipfs.io/ipfs/QmZS1o6iExKm7CEzxyDeuBjYBEvvAczkYLmDrpW8TL4Y8B/";

    //****** EXTERNAL *******/

    /**
     * @dev minting by the queen when it is claimed by a bears deluxe owner
     */
    function mint(address _owner, uint256 _tokenId) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "Missing MINTER_ROLE");
        require(_tokenId > 0 && _tokenId <= MAX_SUPPLY, "Token out of bound");
        require(totalSupply() <= MAX_SUPPLY, "Max supply reached");

        super._safeMint(_owner, _tokenId);
    }

    /**
     * @dev only possible to burn by queen for honey rewards.
     */
    function burnByQueen(uint256 _tokenId) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "Missing BURNER_ROLE");

        super._burn(_tokenId);
    }

    /**
     * @dev in case something happens with a token, metadata can be changed by the owner.
     * only emergency
     */
    function setTokenUri(uint256 _tokenId, string calldata _tokenURI) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(lockedUrlChange == 0, "Locked");

        _setTokenURI(_tokenId, _tokenURI);
        emit UrlChanged(_tokenId, _tokenURI);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Changing base uri for reveals or in case something happens with the IPFS
     */
    function setBaseUri(string calldata _newBaseUri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(lockedUrlChange == 0, "Locked");

        baseUri = _newBaseUri;
        emit UrlChanged(0, _newBaseUri);
    }

    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev returns token ids owned by a owner
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * @dev lock changing url for ever.
     */
    function lockUrlChanging() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");

        lockedUrlChange = 1;
        emit LockedUrl();
    }

    //****** PUBLIC *******/

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");

        string memory _tokenURI = customTokenUris[uint16(_tokenId)];

        // If custom token is set then we return it
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(baseUri, Strings.toString(_tokenId)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC721, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //****** INTERNAL *******/

    function _setTokenURI(uint256 tokenId, string calldata _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721: URI set of nonexistent token");
        customTokenUris[uint16(tokenId)] = _tokenURI;
    }
}

