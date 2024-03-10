pragma solidity ^0.4.11;

import "./ERC721BasicTokenSoloArcade.sol";  
import "./OwnableSolo.sol";
import "./PayableSolo.sol";
import "./ERC721MetadataSoloArcade.sol";


//@title Marbles
//@dev marbles contract inherets ERC721 Non-Fungible Token Standard basic implementation.
//@author Oleg Mitrakhovich                        
contract Marbles is ERC721BasicTokenSoloArcade, OwnableSolo, PayableSolo, ERC721MetadataSoloArcade {

    //@dev basic structure of a marble, 8 attributes.
    struct Marble {
    
        uint256 batch;    //assigns which batch the marble is from (1, 2, 3, 4, etc.)
        string material;  // glass, clay, agate, steel, alabaster
        uint size;        // 12mm, 14mm, 16mm, 18mm, 19mm, 22mm, 25mm, 35mm, 41mm, 48mm
        string pattern;   /*1.Corkscrew Swirls 
                            2.Ribbon Swirls 
                            3.Fancy Swirls 
                            4.Cat’s Eye 
                            5.Clouds 
                            6.Onionskins 
                            7.Bullseye 
                            8.Clearies 
                            9.Opaques
                          */ 

        string origin; /* 1.Germany 
                          2.Belgium 
                          3.Japan 
                          4.China 420
                          5.US 
                          6.Mexico 
                         */
        string forged; // handmade, machined, custom
        string grade;  // mint, near mint, good, exprienced, senior 
        string color;  //list of colors
        
    } 

    //@dev emits add marble attributes event
    //@param _tokenId ID of the token that just had all of its attributes changed
    event addMarbleAttributesConfirmed(uint256 indexed _tokenId);
    

    //@dev stores all the marble prices by its ID.
    mapping(uint256 => uint256) public marblePrices;

    //@dev storing total created marble count
    uint public marbleCount;
    
    
    //@dev storing the count of all place holder marbles.
    uint public placeHolderMarbleCount;

    //@dev stores the highest marble ID created.
    uint public highestMarbleCreated;
    
    //@dev stores the highest Marble ID in the catalaug
    uint public highestMarbleInventory;
    
    //@dev stores highest place holder marble ID created.
    uint public highestPlaceHolderCreated;
    
    //@dev stores all the place holder marbles IDs 
    mapping(uint256 => bool) public placeHolderMarbles;

    //@dev stores marble IDs to marble struct 
    mapping(uint256 => Marble) public marbles; 
    
    //@dev stores all the placeholder marbles by index
    mapping (uint256 => uint256) public placeHolderMarbleIndex;
    
    //@dev first queue number used in placeholdermarbleIndex
    uint256 public first = 1;
    
    //@dev last queue number used in placeholdermarbleIndex
    uint256 public last = 0;
    
    
    //@dev checks to see if the price being used to buy a marble is correct, throws if its not
    modifier priceCheck(uint256 _tokenId) {
       require(marblePrices[_tokenId] == msg.value);
       _;
    }

    
    //@dev upon deployment ETH will be deposited to marbles contract, if there is any.
    constructor () public payable {
        deposit(msg.value);
    }
    
    //@dev fall back function, will execute when someone tries to send ETH to this contract address
    function () public payable {
        deposit(msg.value); //deposit ETH to contract
    }
    
    //@dev returns the total supply of marbles
    function totalSupply() public view returns (uint256 total){
        return marbleCount;
    }

    
     //@dev returns the placeholder marble ID that is located in the first Index.
     function getPlaceHolderMarble() public view returns(uint256 placeholdermarble){
      return placeHolderMarbleIndex[first];
     }

     //@dev returns all marbles of owner by index. should be used on the back end to sync the database. run this in a loop.
     function getMarblesOwnedByIndex(uint256 index, address _owner) public view returns(uint256 marbleId){
      address owner = tokenOwner[index];
      require(owner == _owner);
      return index;
     }

     //@dev returns all marbles created on the contract by index. should be used on the back end to sync. run this in a loop.
     function getAllMarblesCreatedByIndex(uint256 index) public view returns(uint256 marbleId){
      address owner = tokenOwner[index];
      require(owner != address(0));
      return index;
     }

     //@credit CryptoKitties contract (https://ethfiddle.com/09YbyJRfiI) (https://etherscan.io/token/0x06012c8cf97bead5deae237070f9587f8e7a266d#readContract)
     //@dev searches for all the marbles that were assigned to a specific address, returns an array of marble IDs.
     //@dev DO NOT USE THIS FUNCTION inside the contract, it is too expensive and your function call will time out, if their is too many marbles to find. 
     //@dev This function is used to support web3 calls. 
     //@dev When tested with web3 calls this function stopped looking for marbles at 1000 on Rikenby test network.
     //@param _owner wallet address of the owner who owns marble IDs
     function marblesOwned(address _owner) external view returns(uint256[] MarblesOwned) {
        uint256 CountOfMarbles = balanceOf(_owner);   //stores the total number of marbles that are owned by the "_owner" address

        if (CountOfMarbles == 0) {                    //checks to see if the count of marbles is at zero
        
            return new uint256[](0);                  // function returns an empty array of the above if statement returns true  
        
        } else {                                        
        
            uint256[] memory result = new uint256[](CountOfMarbles); //allocating memory in the result array to the count of possible owned marbles by the "_owner"
            uint256 totalMarbles = highestMarbleCreated;             //setting totalMarbles to the highest marble ID. This is done to keep the value constant when used in the for loop.
            uint256 resultIndex = 0;                                 //initializing resultIndex at 0

            uint256 MarbleId;                                        //initializing MarbleId to use later in the for loop 

            for (MarbleId = 1; MarbleId <= totalMarbles; MarbleId++) { //MarbleId gets intialized at 1, the loop will keep going till MarbleId is higher than the total number of Marbles. Adds 1 to MarbleId each loop cycle
                if (tokenOwner[MarbleId] == _owner) { //uses TokenOwner mapping from ERC721BasicToken contract, returns true if MarbleId was mapped to "_owner" address
                    result[resultIndex] = MarbleId;   //stores the MarbleId in a array of uint256 called result, uses resultIndex to expand the array
                    resultIndex++;                    //add one to resultIdex
                }

                if (CountOfMarbles == resultIndex){   //returns the function early when the result count is equal to the total owner's marbles.
                    return result;
                }
            }                                         

            return result;                            //returns an array of MarbleIds
        }
    }
 
    //@dev returns all the marble Token IDs that were created
    //DO NOT USE THIS FUNCTION INTERNALLY. For testing purposes only
    function allMarblesCreated() external view returns(uint256[] MarblesCreated){
        uint256 allMarblesCreatedCount = marbleCount;
        uint256[] memory result = new uint256[](allMarblesCreatedCount); //allocating enough memory to store all the Marble IDs created
        uint256 resultIndex = 0; //setting result index to 0
        uint256 allTokens = highestMarbleCreated;
        uint256 tokenIndex;      //token index that will be used in tokenOwner mapping

        for(tokenIndex = 1; tokenIndex <= allTokens; tokenIndex++){
            if(tokenOwner[tokenIndex] != 0){ //checks if the index of that token owner is not equal to zero
            result[resultIndex] = tokenIndex; //if the above statement returns true, stores the token Id in array called result
            resultIndex++;//increases result index by one
            
            }
        }

        return result;  //returns the final result of all token IDs created
    }
   
    //@dev returns a list of marbles that are still placeholder marbles
    function getPlaceHolderMarbles() external view returns(uint256[] resultPlaceHolders){
              uint256 allPlaceHoldersCreatedCount = placeHolderMarbleCount;
              uint256[] memory result = new uint256[](allPlaceHoldersCreatedCount);
              uint256 resultIndex = 0;
              uint256 allPlaceHolders = highestMarbleCreated;
              uint256 index;

              for(index = 1; index <= allPlaceHolders; index++){
                  if(placeHolderMarbles[index]){
                  result[resultIndex] = index;
                  resultIndex++;
                  }
              }

              return result;
    }


    
    //@dev configures the marble price and stores the highest marble ID currently available for sale
    //@param _newPriceInWei takes in the marble price in wei of one marble
    //@param _highestMarbleInventory takes in the highest token ID currently available in store
    function configStore (uint256 _newPriceInWei, uint256 startingId, uint endingId) external onlyOwner {
                  for(uint i = startingId; i <= endingId; i++){
                    marblePrices[i] = _newPriceInWei;
                  } 
                  
                  if(highestMarbleInventory < endingId){
                      highestMarbleInventory = endingId; //sets the highest marble ID in store catalogue, used inside modifiers to check if the marble ID being requested is a valid one.
                  }            
                   
    }

    //@dev returns the token price in string format, uint to string
    //@credit "ORACLIZE_API" https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    // <ORACLIZE_API>
    /*
    Copyright (c) 2015-2016 Oraclize SRL
    Copyright (c) 2016 Oraclize LTD
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
    */
    function getMarblePrice(uint256 _tokenId) external view returns (string){
                uint256 marblePrice = marblePrices[_tokenId];
               
                if(marblePrice == 0) return "0";
                uint j = marblePrice;
                uint len;
                while(j != 0){
                    len++;
                    j /= 10;
                }

                bytes memory bstr = new bytes(len);
                uint k = len - 1;
                
                while(marblePrice != 0){
                    bstr[k--] = byte(48 + marblePrice % 10);
                    marblePrice /= 10;
                }

                return string(bstr);
    }

           
  
    //@dev used in requestBuy function. Makes sure that token ID was not created on the contract and creates a placeholder structure for that specific marble.
    modifier MarblePlaceHolderCreation(uint256 _marbleId){
        require(!_exists(_marbleId)); //makes sure marble Id was not created on the contract
        require(_marbleId <= highestMarbleInventory); //makes sure marble Id is lower than highest marble ID available for sale
        marbles[_marbleId] = Marble(_marbleId,"NULL", _marbleId, "NULL", "NULL", "NULL", "NULL", "NULL"); //creates a place holder structure for clients future marble
        placeHolderMarbles[_marbleId] = true; //sets marble ID to true for being a placeholder marble
        last += 1;
        placeHolderMarbleIndex[last] = _marbleId;
        placeHolderMarbleCount++;             //adds one to total placeholder marble account, later used for memorory allocation
         if(highestPlaceHolderCreated < _marbleId){ //checks to see if the highest place holder marble created is lower than marble ID.
            highestPlaceHolderCreated = _marbleId; //if above statement is true  sets the current marble ID to highest place holder marble created
        }
        _;
    }
    
    //@dev used in requestBuy function. uses ERC721BasicToken minting function.
    modifier TokenMint(address _wallet, uint256 _tokenId){
        _mint(_wallet, _tokenId); //Mints the token ID of the newest placeholder structure to that wallet address.
        marbleCount++; //adds one to total marble count
        _;
    }

    //@dev before function can be executed it, the priceCheck modifier checks if the price matches to what is stored in marblePrice.
    //IfNotPaused checks to see if the function was paused by the owner of the contract.
    //MarblePlaceHolderCreation creates a marble placeholder structure that will be modified later with attributes from the database
    //TokenMint modifier mints the token Id to that specific wallet, prevents double buying of the same marble in the store.
    //@param _wallet address of a wallet thats making a request to buy a marble
    //@param _tokenId ID of the token thats being requested for purchase
    function requestBuy(uint256 _tokenId) payable external ifNotPaused priceCheck(_tokenId) MarblePlaceHolderCreation(_tokenId) TokenMint(msg.sender, _tokenId) {
                 deposit(msg.value);
    }
     
     //@dev allows the owner of the contract to buy marbles for free
     function requestBuyOwner(uint256 _tokenId) external ifNotPaused onlyOwner MarblePlaceHolderCreation(_tokenId) TokenMint(msg.sender, _tokenId) {
                 
     }

     modifier checkIfMarblePlaceHolder(uint256 _marbleId){
         require(placeHolderMarbles[_marbleId]);
         _;
     }
     
     modifier changePlaceHolderMarbleToFalse(uint256 _marbleId){
         placeHolderMarbles[_marbleId] = false;
         _;
     }
     
     //@dev adds marble attributes to a created marble placeholder
     //@param _tokenId   stores token ID that needs to created
     //@param _material  glass, clay, agate, steel, alabaster
     //@param _size      12mm, 14mm, 16mm, 18mm, 19mm, 22mm, 25mm, 35mm, 41mm, 48mm
     //@param _pattern   1.Corkscrew Swirls 2.Ribbon Swirls 3.Fancy Swirls 4.Cat’s Eyes 5.Clouds 6.Onionskins 7.Bullseye 8.Clearies 9.Opaques
     //@param _origin    1.Germany 2.Belgium 3.Japan 4.China 5.US 6.Mexico 
     //@param _forged    handmade, machined, custom
     //@param _grade     mint, near mint, good, exprienced, senior
     //@param _color     list of colors, Example "188-142-94/229-66-251/63-89-145" 
     //@param _uriBase   takes a string of the URI base string, where metadata for that token will be stored, Example (https://api.cryptomibs.co/marbles/10000)                                                                                                 
    function addMarbleAttributes(uint256 _marbleId, uint256 _batch, string _material, uint _size, string _pattern, string _origin, string _forged, string _grade, string _color, string _uriBase) ifNotPaused onlyCreator checkIfMarblePlaceHolder(_marbleId) changePlaceHolderMarbleToFalse(_marbleId) public  {
        marbles[_marbleId] = Marble(_batch, _material, _size, _pattern, _origin, _forged, _grade, _color); //modifies the placeholder marble.
        setTokenURI(_marbleId, _uriBase); //sets token URI
        
        if(highestMarbleCreated < _marbleId){ //checks to see if the highestMarbleCreated is lower than marble ID.
            highestMarbleCreated = _marbleId; //if the above statement returns true, set the new marble ID to highestMarbleCreated.
        }

        
        
        if(last >= first){
            delete placeHolderMarbleIndex[first];
            first += 1;
        }
       
        if(placeHolderMarbleCount != 0){
        placeHolderMarbleCount--;             //decreases the count of all place holder marbles by one.
        }
        
        emit addMarbleAttributesConfirmed(_marbleId); //emits an events sending the wallet address and marble ID of the token that was created and modified with new attributes from database.
        
    }
    
    //@dev used for games to change marble attributes depending on the result of the game. only one of the pre set creator wallets can use this function.
    function changeMarbleAttributes(uint256 _marbleId, uint256 _batch, string _material, uint _size, string _pattern, string _origin, string _forged, string _grade, string _color) public {
          require(gameContracts[msg.sender]);
          marbles[_marbleId] = Marble(_batch, _material, _size, _pattern, _origin, _forged, _grade, _color);
    }
    
    //@dev returns a transfered  marble ID, for processing
    function getTransferedMarbleId() public view returns(uint256 transferedMarble){
        return transferedMarbleIndex[firstFirst];
    }
    
    //@dev checks if marble ID is a recently transfered marble
    modifier checkIfTransferedMarbleIsTrue(uint256 tokenId){
        require(transferedMarbles[tokenId]);
        _;
    }
    
    //@dev changes the status of the transfered marble to false
    modifier changeTransferedMarbleStatusToFalse(uint256 tokenId){
        transferedMarbles[tokenId] = false;
        _;
    }
    
    //@dev increments the transfer marble queue
    function incrementTransferMarbleIndex(uint256 tokenId) public onlyCreator checkIfTransferedMarbleIsTrue(tokenId) changeTransferedMarbleStatusToFalse(tokenId){
         if(lastLast >= firstFirst){
          delete transferedMarbleIndex[firstFirst];
          firstFirst += 1;
        }
    }
    
    //@dev emergency function that force incrments the transfer queue, can only be used by one of the creator wallets
    function forceIncrementTransferMarbleIndex() public onlyCreator returns(bool increment){
        if(lastLast >= firstFirst){
          delete transferedMarbleIndex[firstFirst];
          firstFirst += 1;
          return true;
        }
        return false;
    }    
    

}
