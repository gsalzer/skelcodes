pragma solidity ^0.5.0;

interface ArtInterface {
    function ownerOf(uint256 _artId) external view returns (address); 
    function safeTransferFrom(address _from, address _to, uint _artId) external;
}

interface CVInterface {
    function safeTransferFrom(address _from, address _to, uint _parcelId) external;
    function ownerOf(uint256 _parcelId) external view returns (address);
}

pragma solidity ^0.5.0;

contract InstantBuy {

    ArtInterface public artContract;
    CVInterface public cvContract;
    
    string contractName = "Instant Buy";
  
    address payable public owner;
    uint256 public priceInWei;
    bool public contractActive;
    
    uint[] public artworks;
    uint public artworksTotal;
    
    uint public parcel;
    
    
    constructor(uint256 initialPriceInWei, address _artContract) public {
        
        artContract = ArtInterface(_artContract);
        cvContract = CVInterface(0x79986aF15539de2db9A5086382daEdA917A9CF0C);
        owner = msg.sender;
        priceInWei = initialPriceInWei;
        artworksTotal=0;
        contractActive=true;
       
    }

    function() external payable {
        require(msg.value==priceInWei);
        require(contractActive==true);
        for (uint i=0; i<artworksTotal; i++){
            artContract.safeTransferFrom(address(this), msg.sender, artworks[i]);
        }
        
        owner.transfer(msg.value);
        if (parcel != 0){
        cvContract.safeTransferFrom(address(this), owner, parcel);
        }
        contractActive=false;
        
    }
    
    function transferArt(address _to, uint256 _artId) public returns (bool){
        require(msg.sender==owner);
        artContract.safeTransferFrom(address(this), _to, _artId);
        return true;
    }
    
    function transferParcel(address _to, uint _parcelID) public returns (bool){
        require (msg.sender==owner);
        cvContract.safeTransferFrom(address(this), _to, _parcelID);
        return true;
    }
    
    function registerArt(uint256 _artId) public returns (bool){
        require(msg.sender==owner);
        require(address(this)==artContract.ownerOf(_artId));
        artworks.push(_artId);
        artworksTotal++;
        return true;
    }
    
    function registerParcel(uint256 _parcelId) public returns (bool){
        require (msg.sender==owner);
        require(address(this)==cvContract.ownerOf(_parcelId));
        parcel = _parcelId;
        return true;
    }
    
    
    function setPrice (uint _priceInWei) public returns (bool){
        require(msg.sender==owner);
        priceInWei = _priceInWei;
        return true;
    }
    
    
}
