pragma solidity ^0.4.25;

import "./SafeMath.sol";
import "./BrightCoinTokenOwner_ICO.sol";

contract BrightCoinFounderTokenDistribution  is BrightCoinTokenOwner
{

  mapping(address => uint256)FounderBalances;
using SafeMath for uint;

 struct founderDistribution {
       address founderAddress;
       uint256 founderToken;
       uint256 lockExpiryTime;
       bool    founderActive;
       bool    tokenlocked;
    }
    
 mapping(address => founderDistribution) founderTokenDetails;
 address[] internal founderAddrs;

constructor() public
{
 
}

//Add Founder Starts

function AddFounder(address _newFounder,uint256 _founderToken,uint256 _lockExpiryDateTime,
 bool _tokenLocked)   internal 
  {

      founderDistribution storage  founderDetails = founderTokenDetails[_newFounder];
    
      founderDetails.founderAddress = _newFounder;
      founderDetails.founderToken = _founderToken;
      founderDetails.lockExpiryTime = _lockExpiryDateTime;
      founderDetails.tokenlocked = _tokenLocked;
      founderDetails.founderActive = true;
      founderAddrs.push(_newFounder);
    
 }


  function  UpdateFounderTokenDetails(address _newFounder,uint256 _founderToken,
  uint256 _lockExpiryDateTime) internal
  {
    require(CheckIfFounderActive(_newFounder) == true);   
     //Add new Token amount and Set new locking Period
      founderDistribution storage  founderDetails = founderTokenDetails[_newFounder];
     founderDetails.founderToken  = founderDetails.founderToken.add(_founderToken);
     founderDetails.lockExpiryTime = _lockExpiryDateTime;     
  }

//Remove Founder For Further Investment and from the Team
 function RemoveFounderFromFurtherInvestment(address _newFounderAddr)  public onlyTokenOwner  returns(bool)
 {
   founderDistribution storage newFounderDetails = founderTokenDetails[_newFounderAddr];
   newFounderDetails.founderActive = false;
    
    return true;

 }

//ENDS

//check if Founder Removed 
 function CheckIfFounderActive(address _newFounderAddr) view internal returns(bool)
 {

  founderDistribution storage founderDetails = founderTokenDetails[_newFounderAddr];
 if(founderDetails.founderActive == true)
  {
      return true;
  }
  
  return false;

 }



//Count total no of Advisors
 function TotalFounder() public view returns(uint256) 
 {
   return founderAddrs.length;
  
 }


 //check Amount with Advisor
 function CheckFounderTokenAmount(address _newFounderAddr) view public returns(uint256)
 {

  founderDistribution storage founderDetails = founderTokenDetails[_newFounderAddr];
  return founderDetails.founderToken;
   
 }

}


 
    
