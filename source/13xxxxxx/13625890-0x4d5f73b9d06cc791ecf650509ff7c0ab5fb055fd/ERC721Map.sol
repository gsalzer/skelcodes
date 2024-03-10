pragma solidity 0.8.3;

import "./Withdrawable.sol";
import "./ERC721.sol";

contract ERC721Map is Withdrawable {

    event ERC721NameSet(address indexed _address, uint256 indexed _tokenId, string _name);
    event AddressBanned(address indexed _address);
    event AddressUnbanned(address indexed _address);

    // All added addresses are ERC721
    mapping(address => mapping(uint256 => string)) contractToMap;

    bool public isPaused;

    constructor() public {
        isPaused = false;
    }

    // Banned owners 
    mapping (address => bool) public bannedAddresses;

    function isBanned(address _address) external view returns(bool){
        return bannedAddresses[_address];
    }

    /**
    * Banning the address will make the contract ignore all the records 
    * that blocked address owns. This blocks NFT owners NOT contract addresses. 
     */
    function ban(address _address) public onlyOwner {
        bannedAddresses[_address] = true;
        emit AddressBanned(_address);
    }

    function unban(address _address) public onlyOwner {
        bannedAddresses[_address] = false;
        emit AddressUnbanned(_address);
    }

    /**
    * When contract is paused it's impossible to set a name. We leave a space here to migrate to a new 
    * contract and block current contract from writting to it while making the read operations 
    * possible. 
    */
    function setIsPaused(bool _isPaused) public onlyOwner {
        isPaused = _isPaused;
    }

    function _setTokenName(address _address, uint256 _tokenId, string memory _nftName) internal {
        ERC721 nft = ERC721(_address);

        require(!isPaused);
        require(nft.supportsInterface(0x80ac58cd));
        require(nft.ownerOf(_tokenId) == msg.sender);

        contractToMap[_address][_tokenId] = _nftName;
        emit ERC721NameSet(_address, _tokenId, _nftName);
    }

    function getTokenName(address _address, uint256 _tokenId) external view returns(string memory) {
        ERC721 nft = ERC721(_address);
        require(nft.supportsInterface(0x80ac58cd));
        require(!this.isBanned(nft.ownerOf(_tokenId)));

        return contractToMap[_address][_tokenId];
    }

    /**
    * For testing purposes, it's not really required. You may test if your contract 
    * is compatible with our service. 
    *
    * @return true if contract is supported. Throws an exception otherwise. 
    */
    function isContractSupported(address _address) external view returns (bool) {
            ERC721 nft = ERC721(_address);

            // 0x80ac58cd is ERC721 
            return nft.supportsInterface(0x80ac58cd);
    }

}
