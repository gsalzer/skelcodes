pragma solidity ^0.4.11;

import "./ERC721BasicTokenSoloArcade.sol";  
import "./OwnableSolo.sol";

contract ERC721MetadataSoloArcade is ERC721BasicTokenSoloArcade, OwnableSolo {

    
    //@dev declares the token name as "Marble"
	string public constant name = "Marble";
    
    //@dev declares the token symbol as "MIB"
    string public constant symbol = "MIB";

    //@dev mapping for token URIs
    mapping(uint256 => string) public tokenURIs;

    //@dev function which sets the token URI, throws if token ID does not exist, only wallet address that is set as creator can set meta data
    //@param tokenId ID of the token to set its URI 
    //@param uri string URI to assign  (example https://api.cryptomibs.co/marbles/)
    function setTokenURI(uint256 tokenId, string uri) onlyCreator public {
        
        if(bytes(tokenURIs[tokenId]).length != 0){ //checks if there is already any metadata recorded for that token ID.
           delete tokenURIs[tokenId];       //clears old metadata if any, for that token ID
        }

        require(_exists(tokenId));   //checks to see if tokenId exists
        
        tokenURIs[tokenId] = uri;    // sets token URI to a given string in tokenURIs mapping

    }

    //@dev returns a URI for a given token ID, throws if token ID does not exists. Turns the URI into bytes and concatenates the token ID to the end of URI base
    //This method uses a turorial from coinmonks.
    //Ref: https://medium.com/coinmonks/jumping-into-solidity-the-erc721-standard-part-6-7ea4af3366fd
    //@param tokenId ID of token to query
    function tokenURI(uint256 tokenId) public view returns (string){
        require(_exists(tokenId)); //checks if token ID exists.
        
        bytes storage uriBase = bytes(tokenURIs[tokenId]);  
    
        //prepare our tokenId's byte array
        uint maxLength = 78;
        bytes memory reversed = new bytes(maxLength);
        uint i = 0;
    
        //loop through and add byte values to the array
        while (tokenId != 0) {
        uint remainder = tokenId % 10;
        tokenId /= 10;
        reversed[i++] = byte(48 + remainder);
        }
    
        //prepare the final array
        bytes memory result = new bytes(uriBase.length + i);
        uint j;
        //add the base to the final array
        for (j = 0; j < uriBase.length; j++) {
        result[j] = uriBase[j];
        }
    
        //add the tokenId to the final array
        for (j = 0; j < i; j++) {
        result[j + uriBase.length] = reversed[i - 1 - j];
        }  
    

        return string(result);  //turn it into a string and return it  
    

    }

}
