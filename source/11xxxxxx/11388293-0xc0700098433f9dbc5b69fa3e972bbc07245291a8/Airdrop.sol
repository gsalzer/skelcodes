pragma solidity 0.5.17;

import "./SafeMath.sol";
import "./MorpheusToken.sol";
import "./Ownable.sol";

contract Airdrop is Ownable {
    
    using SafeMath for uint256;
    
    // Tokens used in game
    MorpheusToken public morpheus;
    
    //Mapping for address already airdroped
    mapping(address => bool) asBeenAirdroped;
    
    constructor(MorpheusToken _morpheusToken) public {
        //init Morpheus token address
        setMorpheusToken(_morpheusToken);
    }
    
    // Set the MorpheusToken address
    function setMorpheusToken(MorpheusToken _morpheusToken) public onlyOwner() {
        morpheus = _morpheusToken;
    }
    
    //Send tokens to contract // need to be allowed
    function sendToken(uint256 _amount) public onlyOwner(){
        uint256 amount = _amount.mul(1E18);
        morpheus.transferFrom(msg.sender, address(this), amount);
    }
    
    function airdrop(uint256 _amount, address[] memory _recipients)public onlyOwner(){
        uint256 amount = _amount.mul(1E18);
        for(uint256 i=0; i<_recipients.length;i++){
            if(asBeenAirdroped[_recipients[i]] == false){
                asBeenAirdroped[_recipients[i]] == true;
                morpheus.transfer(_recipients[i],amount);   
            }

        }
    }
}

