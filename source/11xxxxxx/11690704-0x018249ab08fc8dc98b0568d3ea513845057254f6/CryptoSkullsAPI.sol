pragma solidity 0.4.24;

contract CryptoSkulls {
    
    function supportsInterface(bytes4) public pure returns (bool) {}
    function name() public pure returns (string) {}
    function getApproved(uint) public pure returns (uint) {}
    function totalSupply() public pure returns (uint) {}
    function tokenOfOwnerByIndex(address, uint) public pure returns (uint) {}
    function tokenByIndex(uint) public pure returns (uint) {}
    function imageHash() public pure returns (string) {}
    function ownerOf(uint) public pure returns (address) {}
    function balanceOf(address) public pure returns (uint) {}
    function owner() public pure returns (address) {}
    function isOwner() public pure returns (bool) {}
    function symbol() public pure returns (string) {}
    function isApprovedForAll(address, address) public pure returns (bool) {}

}

contract CryptoSkullsAPI {
    modifier onlyAuthor {
        require(msg.sender == author);
        _;
    }
    
    CryptoSkulls pullContract;
    
    address public author;
    address public tokenAddress;
    string public imageHash;
    string public imageHashURI;
    string public tokenURI;
   
    constructor() public {
        author = msg.sender;
        tokenAddress = 0xc1Caf0C19A8AC28c41Fe59bA6c754e4b9bd54dE9;
        imageHashURI = 'https://ipfs.io/ipfs/QmXVHusfnw2vK3VMQinasuQXpcwUHEBauDwnWGrCoJ6dgy';
        tokenURI = 'https://gateway.ethswarm.org/files/cd8633ae1ee6c310366e72154f22edfca28ab87bbda7a2282d33cf7e2426c585';
        pullContract = CryptoSkulls(tokenAddress);   
        emit _UpdateContract(tokenAddress, imageHashURI, tokenURI);
    }
          
    
    function killContract() public onlyAuthor { 
        selfdestruct(author); 
    }
    
    function transferOwnership(address _author) public onlyAuthor { 
        author = _author; 
        
        emit _transferOwnership(msg.sender, _author);
    }
    
    
    function updateContract(address _tokenAddress,  string _imageHashURI, string _tokenURI) public onlyAuthor { 
        tokenAddress = _tokenAddress;
        imageHashURI = _imageHashURI;
        tokenURI = _tokenURI;
        pullContract = CryptoSkulls(_tokenAddress);
        emit _UpdateContract(_tokenAddress, _imageHashURI, _tokenURI);
    }
    
      
    function supportsInterface(bytes4 interfaceId ) constant public returns (bool) {
        return pullContract.supportsInterface(interfaceId);
    }
    
    function name() constant public returns (string) {
        return pullContract.name();
    }
    
    function getApproved(uint tokenId) constant public returns (uint) {
        return pullContract.getApproved(tokenId);
    }
    
    function totalSupply() constant public returns (uint) {
        return pullContract.totalSupply();
    }
    
    function tokenOfOwnerByIndex(address owner, uint index) constant public returns (uint) {
        return pullContract.tokenOfOwnerByIndex(owner, index);
    }
    
    function tokenByIndex(uint index) constant public returns (uint) {
        return pullContract.getApproved(index);
    }
    
    function imageHash() constant public returns (string) {
        return pullContract.imageHash();
    }
    
    function ownerOf(uint tokenId) constant public returns (address) {
        return pullContract.ownerOf(tokenId);
    }
    
    function balanceOf(address owner) constant public returns (uint) {
        return pullContract.balanceOf(owner);
    }
    
    function owner(address) constant public returns (address) {
        return pullContract.owner();
    }
    
    function isOwner() constant public returns (bool) {
        return pullContract.isOwner();
    }
    
    function symbol() constant public returns (string) {
        return pullContract.symbol();
    }
    
    function isApprovedForAll(address owner, address operator) constant public returns (bool) {
        return pullContract.isApprovedForAll(owner, operator);
    }
    
    
event   _UpdateContract(address newTokenAddress, string newImageHashURI, string newTokenURI);
event   _transferOwnership(address oldAuthor, address newAuthor);
    
}
