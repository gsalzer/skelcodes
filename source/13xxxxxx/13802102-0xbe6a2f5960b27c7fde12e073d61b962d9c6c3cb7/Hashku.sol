// SPDX-License-Identifier: MIT

/*
*
* Hashku Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used as base contract for ERC721 when minting on Hashku
*
*/

pragma solidity 0.8.10;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";
import "./Context.sol";
import "./Counters.sol";
import "./ECDSA.sol";
import "./SafeMath.sol";

contract Hashku is Context, Ownable, ERC721, IERC2981 {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;
    using ECDSA for bytes32;

    Counters.Counter private tokenIdTracker;

    string public baseTokenURI;
    string public key = "SHOP";
    string public group = "init";
    uint256 internal maxMintPerAddressNumber;
    uint256 internal maxMintPerTransactionNumber;
    uint256 public maxTokens;
    uint256 internal priceNumber;
    bool public isPublic;
    bool public isClosed;
    mapping(address => uint256) public tokensMinted;
    address public withdrawalAddress;
    address public verifySigner;
    uint256 public royaltyPercent;
    address public proxyRegistryAddress;

    event ContractUpdated(string _type);

    modifier onlyWithdrawer() {
        require(withdrawalAddress != address(0), "no_withdrawals");
        require(withdrawalAddress == _msgSender(), "not_allowed");
        _;
    }

    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _baseTokenURI,
        string memory _key,
        uint256 _maxTokens, 
        uint256 _maxMintPerAddress,
        uint256 _maxMintPerTransaction,
        uint256 _price,
        uint256 _royaltyPercent,
        address _withdrawalAddress
    ) ERC721(_name, _symbol) {
        baseTokenURI = _baseTokenURI;
        key = _key;
        maxTokens = _maxTokens;
        maxMintPerAddressNumber = _maxMintPerAddress;
        maxMintPerTransactionNumber = _maxMintPerTransaction;
        priceNumber = _price;
        royaltyPercent = _royaltyPercent;
        withdrawalAddress = _withdrawalAddress;
        verifySigner = _msgSender();
    }

    // support IERC2981
    function supportsInterface(bytes4 _interfaceId) public view virtual override (ERC721, IERC165) returns (bool) {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    // return the token URI for a specific token
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "no_token");

        return bytes(baseTokenURI).length > 0 ? string(abi.encodePacked(baseTokenURI, _tokenId.toString())) : "";
    }

    // internal mint function, incrementing token
    function mint(address _to) internal {
        _safeMint(_to, tokenIdTracker.current());
        tokenIdTracker.increment();
    }

    // owner sends NFTs to addresses
    function send(address[] calldata _addresses, uint256[] calldata _amounts) external onlyOwner {
        require(_addresses.length == _amounts.length, "amount_mismatch");

        uint256 total;
        for (uint256 t = 0; t < _amounts.length; t++) {
            total += _amounts[t];
        }

        require(nextToken() + total <= maxTokens, "not_enough_tokens");

        delete total;

        for (uint256 i = 0; i < _addresses.length; i++) {
            for (uint256 a = 0; a < _amounts[i]; a++) {
                mint(_addresses[i]);
            }
        }
    }

    // buy NFTs - version without signature required for public mint
    function shop(uint256 _amount) external virtual payable {
        require(nextToken() + _amount <= maxTokens, "not_enough_tokens");
        if (maxMintPerAddressNumber > 0) {
            require(tokensMinted[_msgSender()] + _amount <= maxMintPerAddressNumber, "max_minted");
        }
        if (maxMintPerTransactionNumber > 0) {
            require(_amount <= maxMintPerTransactionNumber, "max_mintable");
        }
        require(!isClosed, "is_closed");
        require(isPublic, "not_public");
        require(priceNumber * _amount == msg.value, "incorrect_funds");
        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    // buy NFTs
    function shop(uint256 _amount, bytes memory _signature) external virtual payable {
        require(nextToken() + _amount <= maxTokens, "not_enough_tokens");
        if (maxMintPerAddressNumber > 0) {
            require(tokensMinted[_msgSender()] + _amount <= maxMintPerAddressNumber, "max_minted");
        }
        if (maxMintPerTransactionNumber > 0) {
            require(_amount <= maxMintPerTransactionNumber, "max_mintable");
        }
        require(!isClosed, "is_closed");
        require(verifySignature(_signature), "invalid_signature");
        require(priceNumber * _amount == msg.value, "incorrect_funds");

        for (uint256 i = 0; i < _amount; i++) {
            mint(_msgSender());
        }
    }

    // return the id for the next token that will be minted
    function nextToken() public view returns (uint256) {
        return tokenIdTracker.current();
    }

    // convenience method for front end to call contract and check if a user can mint
    function canMint(uint256 _amount) public view virtual returns (bool) {
        if (maxTokens > 0) {
            if (nextToken() + _amount > maxTokens) {
                return false;
            }
        }

        if (maxMintPerTransactionNumber > 0) {
            if (_amount > maxMintPerTransactionNumber) {
                return false;
            }
        }

        if (maxMintPerAddressNumber > 0) {
            if (tokensMinted[_msgSender()] + _amount > maxMintPerAddressNumber) {
                return false;
            }
        }

        return true;
    }

    // convenience function used by dapp to check max for interface
    function price() public view virtual returns (uint256) {
        return priceNumber;
    }

    // convenience function used by dapp to check max for interface
    function maxMintPerAddress() public view virtual returns (uint256) {
        return maxMintPerAddressNumber;
    }

    // convenience function used by dapp to check max for interface
    function maxMintPerTransaction() public view virtual returns (uint256) {
        return maxMintPerTransactionNumber;
    }

    // check if a msg sender is eligible to shop - public version without signature required
    function eligible() public view virtual returns (bool) {
        if (isClosed) {
            return false;
        }

        return isPublic;
    }

    // check if a msg sender is eligible to shop
    function eligible(bytes memory _signature) public view virtual returns (bool) {
        if (isClosed) {
            return false;
        }

        if (isPublic) {
            return true;
        }

        return verifySignature(_signature);
    }

    // owner can ONLY decrease the total number of available tokens
    function decreaseMaxTokens(uint256 _amount) external virtual onlyOwner {
        require(_amount < maxTokens, "only_decrease");
        maxTokens = _amount;
        emit ContractUpdated("maxTokens");
    }

    // owner set the contract to public mode
    function setIsPublic(bool _public) external virtual onlyOwner {
        isPublic = _public;
        emit ContractUpdated("isPublic");
    }

    // owner set the contract to closed
    function setIsClosed(bool _closed) external virtual onlyOwner {
        isClosed = _closed;
        emit ContractUpdated("isClosed");
    }

    // owner set the price of minting
    function setPrice(uint256 _price) external virtual onlyOwner {
        priceNumber = _price;
        emit ContractUpdated("price");
    }

    // set the maximum amount an address may mint
    function setMaxMintPerAddress(uint256 _amount) external virtual onlyOwner {
        maxMintPerAddressNumber = _amount;
        emit ContractUpdated("maxMintPerAddress");
    }

    // set the maximum amount an address may mint
    function setMaxMintPerTransaction(uint256 _amount) external virtual onlyOwner {
        maxMintPerTransactionNumber = _amount;
        emit ContractUpdated("maxMintPerTransaction");
    }

    // owner set the contract key for signature verification
    function setKey(string calldata _key) external virtual onlyOwner {
        key = _key;
        emit ContractUpdated("key");
    }

    // set the current contract group for signature verification
    function setGroup(string memory _group) external virtual onlyOwner {
        group = _group;
        emit ContractUpdated("group");
    }

    // owner set a new base token URI
    function setBaseUri(string calldata _baseTokenURI) external virtual onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit ContractUpdated("baseURI");
    }

    // owner set a new address for signature verification
    function setVerifySigner(address _verifySigner) external virtual onlyOwner {
        verifySigner = _verifySigner;
        emit ContractUpdated("verifySigner");
    }

    // verify signature based on contract key, contract group, token amount, and the msg sender
    function verifySignature(
        bytes memory _signature
    ) internal view virtual returns (bool) {
        bytes32 _messageHash = keccak256(abi.encodePacked(key, group, _msgSender()));

        return _messageHash.toEthSignedMessageHash().recover(_signature) == verifySigner;
    }

    // set the royalty percent
    function setRoyaltyPercent(uint256 _amount) external virtual onlyOwner {
        royaltyPercent = _amount;
        emit ContractUpdated("royaltyPercent");
    }

    // EIP-2981 royaltyInfo
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view virtual override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "no_token");

        return (address(this), SafeMath.div(SafeMath.mul(_salePrice, royaltyPercent), 100));
    }

    // withdrawal address convenience method for pulling balance of contract
    function seeBalance() external view virtual onlyWithdrawer returns (uint256) {
        return address(this).balance;
    }

    // withdrawal address send an amount to an address
    function withdraw(address payable _to, uint256 _amount) external virtual onlyWithdrawer returns (bool) {
        require(_amount <= address(this).balance, "insufficient_funds");
        _to.transfer(_amount);
        return true;
    }

    // withdrawal address set a new withdrawal address
    function setWithdrawalAddress(address _address) external virtual onlyWithdrawer {
        withdrawalAddress = _address;
        emit ContractUpdated("withdrawalAddress");
    }

    // owner can set the proxy registry access after deploy
    function setProxyRegistryAddress(address _proxy) external virtual onlyOwner {
        // OpenSea Rinkeby Address = "0xf57b2c51ded3a29e6891aba85459d600256cf317";
        // OpenSea Mainnet Address = "0xa5409ec958c83c3f309868babaca7c86dcb077c1";
        proxyRegistryAddress = _proxy;
        emit ContractUpdated("proxyRegistryAddress");
    }

    // override isApprovedForAll to allow proxy address for OpenSea gasless listing
    function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
        if (proxyRegistryAddress != address(0)) {
            ProxyRegistry _proxyRegistry = ProxyRegistry(proxyRegistryAddress);
            if (address(_proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

