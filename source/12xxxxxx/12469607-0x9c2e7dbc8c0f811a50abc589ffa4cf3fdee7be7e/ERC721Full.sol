pragma solidity ^0.5.0;
import "./Ownable.sol";
import "./Context.sol";
import "./Pausable.sol";

contract ERC721 is Context, ERC165, IERC721, Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    
    event HorseBought(address indexed owner, uint256 indexed tokenId, string horseType, uint64 horseSubType, uint64 birthTime, string tokenUri );
    event HorseTransferred(address indexed from, address indexed to, uint256 indexed tokenId, string horseType, uint64 horseSubType, uint64 birthTime, string tokenUri );
    
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    mapping(address => Counters.Counter) public r_stallionsCount;
    mapping(address => Counters.Counter) public m_stallionsCount;
    mapping(address => Counters.Counter) public l_stallionsCount;
    mapping(address => Counters.Counter) public maresCount;
    mapping(uint256 => string) public tokenUriMapping;
   
    mapping(uint256 => string) public horseTypes;
    mapping(uint256 => uint64) public horseSubTypes;
    
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721);
    }
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }
    function approve(address to, uint256 tokenId) public whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }
    
    function transferFromOffer(address from, address to, uint256 tokenId) internal whenNotPaused {
        _transferFrom(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public whenNotPaused {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        if( keccak256(bytes(horseTypes[tokenId])) == keccak256(bytes('stallion')) ) {
            if( horseSubTypes[tokenId] == 1 ) {
                r_stallionsCount[to].increment();
            } else if( horseSubTypes[tokenId] == 2 ) {
                m_stallionsCount[to].increment();
            } else if( horseSubTypes[tokenId] == 3 ) {
                l_stallionsCount[to].increment();
            }
          emit HorseBought( to, tokenId, 'stallion', horseSubTypes[tokenId], uint64(now), tokenUriMapping[tokenId] );
        } else {
          maresCount[to].increment();
          emit HorseBought( to, tokenId, 'mare', 0, uint64(now), tokenUriMapping[tokenId] );
        }

        emit Transfer(address(0), to, tokenId);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        if( keccak256(bytes(horseTypes[tokenId])) == keccak256(bytes('stallion')) ) {
          if( horseSubTypes[tokenId] == 1 ) {
              r_stallionsCount[from].decrement();
              r_stallionsCount[to].increment();
           } else if( horseSubTypes[tokenId] == 2 ) {
              m_stallionsCount[from].decrement();
              m_stallionsCount[to].increment();
           } else if( horseSubTypes[tokenId] == 3 ) {
              l_stallionsCount[from].decrement();
              l_stallionsCount[to].increment();
           }
          
          emit HorseTransferred( from, to, tokenId, 'stallion', horseSubTypes[tokenId], uint64(now), tokenUriMapping[tokenId] );
          
        } else {
          maresCount[from].decrement();
          maresCount[to].increment();
          
          emit HorseTransferred( from, to, tokenId, 'mare', 0, uint64(now), tokenUriMapping[tokenId] );
        }

        emit Transfer(from, to, tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool) {
        if ( isContract(to) ) {
            return true;
        }
        (bool success, bytes memory returndata) = to.call(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ));
        if (!success) {
            if (returndata.length > 0) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            }
        } else {
            bytes4 retval = abi.decode(returndata, (bytes4));
            return (retval == _ERC721_RECEIVED);
        }
    }
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
    mapping(address => uint256[]) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    constructor () public {
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        _ownedTokens[from].length--;
    }
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}


contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
    string private _name;
    string private _symbol;
    string private _baseURI;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function name() external view returns (string memory) {
        return _name;
    }
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = tokenUriMapping[tokenId];
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        tokenUriMapping[tokenId] = _tokenURI;
    }
    function _setBaseURI(string memory baseURI) internal {
        _baseURI = baseURI;
    }
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }
}
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
        // solhint-disable-previous-line no-empty-blocks
    }
}

