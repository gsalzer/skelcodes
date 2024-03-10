pragma solidity ^0.4.25;

import "./BrightCoinTokenOwner_ICO.sol";
import "./SafeMath.sol";

contract BrightCoinAdvisorTokenDistribution  is BrightCoinTokenOwner
{


using SafeMath for uint;
mapping(address => uint256)AdvisorBalances;


constructor() public
{

}
  //There might be multiple entry to this
 uint256 public TotalAllocatedAdvisorToken;
 
 
 struct advisorDistribution {
        address addr;
        uint256 tokenamount;
        uint256 expiryDateTime;
        bool   advisorpartofTeam;
        bool  tokenlocked;
    }
 mapping(address => advisorDistribution) advisorDistributionDetails;
 address[] public advisorDistributionAddr;
 
 
 //Advisor Starts
//Adding New Advisor for Token Distribution
 function AddAdvisor(address _newAdvisor,uint256 _tokenamount,uint256 _lockexpiryTime,bool _tokenlocked)   internal
  {
    
        advisorDistribution storage  advisorDetails = advisorDistributionDetails[_newAdvisor];

       advisorDetails.addr = _newAdvisor;
       advisorDetails.tokenamount = _tokenamount;
       advisorDetails.expiryDateTime = _lockexpiryTime;
       advisorDetails.advisorpartofTeam = true;
       advisorDetails.tokenlocked   = _tokenlocked;

       advisorDistributionAddr.push(_newAdvisor);
 
 }

function UpdateAdvisorTokenDetails (address _newAdvisor,uint256 _tokenamount,
  uint256 _lockExpiryDateTime) internal
{
 require(CheckIfAdvisorActive(_newAdvisor) == true);
  advisorDistribution storage  advisorDetails = advisorDistributionDetails[_newAdvisor];
                  
   //Add new Token amount and Set new locking Period
   advisorDetails.tokenamount  = advisorDetails.tokenamount.add(_tokenamount);
   advisorDetails.expiryDateTime = _lockExpiryDateTime;

        
}

 //Remove Advisor For Further Investment and from the Team
 function RemoveAdvisorFromFurtherInvestment(address _newAdvisorAddr) public onlyTokenOwner  returns(bool)
 {
    advisorDistribution storage newAdvisorDetails = advisorDistributionDetails[_newAdvisorAddr];
    newAdvisorDetails.advisorpartofTeam = false;
    return true;
 }

 //Ends


 //check if Advisor Removed 
 function CheckIfAdvisorActive(address _newAdvisorAddr) view internal returns(bool)
 {

  advisorDistribution storage advisorDetails = advisorDistributionDetails[_newAdvisorAddr];
  if(advisorDetails.advisorpartofTeam == true)
  {
      return true;
  }
  return false;

 }

//Count total no of Advisors
 function TotalAdvisor() public onlyTokenOwner  view returns(uint256) 
 {
   return advisorDistributionAddr.length;
 }


 //check Amount with Advisor
 function CheckAdvisorTokenAmount(address _newAdvisorAddr) public onlyTokenOwner  view returns(uint256)
 {

  advisorDistribution storage advisorDetails = advisorDistributionDetails[_newAdvisorAddr];
  return advisorDetails.tokenamount ;

 }

 }

