pragma solidity 0.5.17;

import "./Ownable.sol";
import "./Rabbits.sol";
import "./MorpheusToken.sol";
import "./SafeMath.sol";

// Market Place contract

contract MarketPlace is Ownable {
    
    using SafeMath for uint256;
    
    // Tokens used in the farming
    Rabbits public rabbits;
    MorpheusToken public morpheus;
    
    constructor(Rabbits _rabbits, MorpheusToken _morpheusToken) public{
        //init Rabbits token address
        setRabbitsToken(_rabbits);
        setMorpheusToken(_morpheusToken);
    }
    
    event newSellingInstance(uint256 _tokenId, uint256 _amountAsked);
    event rabbitSold(uint256 _tokenId, address _newOwner);
    event sellingCanceled(uint256 _tokenId);
    
    // =========================================================================================
    // Setting Tokens Functions
    // =========================================================================================

    
    // Set the RabbitToken address
    function setRabbitsToken(Rabbits _rabbits) public onlyOwner() {
        rabbits = _rabbits;
    }
    
    // Set the MorpheusToken address
    function setMorpheusToken(MorpheusToken _morpheusToken) public onlyOwner() {
        morpheus = _morpheusToken;
    }
    
    // =========================================================================================
    // Setting Tokens Functions
    // =========================================================================================

    //Counter
    uint256 onSaleQuantity = 0;
    uint256[] public tokensOnSale;

    struct sellInstance{
        uint256 tokenId;
        uint256 amountAsked;
        bool onSale;
        address owner;
    }
    
    mapping(uint256 => sellInstance) public sellsInstances;
    
    // sell myrabbit
    function sellingMyRabbit(uint256 _tokenId, uint256 _amountAsked) public {
        require(rabbits.ownerOf(_tokenId) == msg.sender, "Not your Rabbit");
        rabbits.transferFrom(msg.sender,address(this),_tokenId);
        sellsInstances[_tokenId] = sellInstance(_tokenId,_amountAsked,true,msg.sender);
        onSaleQuantity = onSaleQuantity.add(1);
        tokensOnSale.push(_tokenId);
        emit newSellingInstance(_tokenId,_amountAsked);
    }
    
    // cancel my selling sellInstance
    function cancelMySellingInstance(uint256 _tokenId)public{
        require(sellsInstances[_tokenId].owner == msg.sender, "Not your Rabbit");
        rabbits.transferFrom(address(this),msg.sender,_tokenId);
        uint256 index = getSellingIndexOfToken(_tokenId);
        delete tokensOnSale[index];
        delete sellsInstances[_tokenId];
        onSaleQuantity = onSaleQuantity.sub(1);
        emit sellingCanceled(_tokenId);
    }
    
    // buy the NFT rabbit
    // Need amount of Morpheus allowed to contract
    function buyTheRabbit(uint256 _tokenId, uint256 _amount)public{
        require(sellsInstances[_tokenId].onSale == true,"Not on Sale");
        require(_amount == sellsInstances[_tokenId].amountAsked,"Not enough Value");
        uint256 amount = _amount.mul(1E18);
        require(morpheus.balanceOf(msg.sender) > amount, "You don't got enough MGT");
        morpheus.transferFrom(msg.sender,sellsInstances[_tokenId].owner,amount);
        rabbits.transferFrom(address(this),msg.sender,_tokenId);
        uint256 index = getSellingIndexOfToken(_tokenId);
        delete tokensOnSale[index];
        delete sellsInstances[_tokenId];
        onSaleQuantity = onSaleQuantity.sub(1);
        emit rabbitSold(_tokenId,msg.sender);
    }
    
    function getSellingIndexOfToken(uint256 _tokenId) private view returns(uint256){
        require(sellsInstances[_tokenId].onSale == true, "Not on sale");
        uint256 index;
        for(uint256 i = 0 ; i< tokensOnSale.length ; i++){
            if(tokensOnSale[i] == _tokenId){
                index = i;
                break;
            }
        }
        return index;
    }
    
}

