pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";

/**
 * @title Finannel
 */
contract Fiannel is ERC1155 {
    
    constructor (string memory uri) public ERC1155(uri) {
        // solhint-disable-previous-line no-empty-blocks
    }
    
     function name() external pure returns (string memory _name) {
        return "Finannel";
    }
    
    function setURI(string memory newuri) public {
        _setURI(newuri);
    }
    
    function mint(string memory operatorAlias,address to,string memory uri,uint id, uint256 value, bytes memory data) public {
        if(id==0){
            id = generateTokenId(msg.sender,uri,value,to);
        }else{
           require(!_checkERC1155AndCallSafeTransfer(id),'The additional id does not exist');
        }
        
        if(_checkERC1155AndCallSafeTransfer(id)){
              id = generateTokenId(msg.sender,uri,value,to);
        }
        
        _mint(msg.sender,operatorAlias,uri,to, id, value, data);
    }
    
    function mintTosBatch(string memory operatorAlias,address[] memory tos,string memory uri, uint256 value, bytes memory data) public {
        uint256 id = generateTokenId(msg.sender,uri,value,getAdmin());
        
        _mintTosBatch(msg.sender,operatorAlias,uri,tos, id, value, data);
    }
    
    function mintBatch(string memory operatorAlias,address to,string[] memory uris,uint256[] memory ids, uint256[] memory values, bytes memory data) public {
        require(ids.length==uris.length&&uris.length==values.length,'Batch mint length is different');
        if(ids.length==0){
            ids = generateTokenIds(msg.sender,ids,uris,values,to); 
        }else{
            for(uint i = 0; i<ids.length;i++){
                require(!_checkERC1155AndCallSafeTransfer(ids[i]),'The additional id does not exist');
            }
        }
        
        _mintBatch(msg.sender,operatorAlias,uris,to, ids, values, data);
    }
    
    function burn(address owner, uint256 id, uint256 value) public {
        _burn(owner, id, value);
    }

    function burnBatch(address owner, uint256[] memory ids, uint256[] memory values) public {
        _burnBatch(owner, ids, values);
    }
    
    function tokenCreator(uint256 id)public view returns(address,string memory){
        return (_tokens[id].creator,_tokens[id].operatorAlias);
    }

}
