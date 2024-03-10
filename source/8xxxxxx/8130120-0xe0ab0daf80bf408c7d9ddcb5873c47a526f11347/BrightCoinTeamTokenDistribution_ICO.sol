
pragma solidity ^0.4.25;

import "./BrightCoinTokenOwner_ICO.sol";

contract BrightCoinTeamTokenDistribution  is BrightCoinTokenOwner
{


  mapping(address => uint256)TeamBalances;
constructor() public
{
 
}

//Team Distribution  
 //There might be multiple entry to this
 uint256 public TotalAllocatedTeamToken;
 
 
 struct teamDistribution {
        address addr;
        uint256 tokenamount;
        uint256 lockexpiry;
        bool   teamActiveInvestor;  //To Ensure if team is still on
        bool tokenlocked;
    
    }

 mapping(address => teamDistribution) teamDistributionDetails;
 address[] public teamTokenDetailsAddr;
 

 //Team Token Distribution  Starts

//Addng Details to Team Token
 function AddTeam(address _newTeamAddr,uint256 _tokenamount,
 uint256 _lockexpirydate,
 bool _tokenLocked)  internal {
     
  teamDistribution storage teamDetails = teamDistributionDetails[_newTeamAddr];
    teamDetails.addr = _newTeamAddr;
    teamDetails.tokenamount = _tokenamount;
    teamDetails.lockexpiry = _lockexpirydate;
    teamDetails.teamActiveInvestor = true;
    teamDetails.tokenlocked = _tokenLocked;
    teamTokenDetailsAddr.push(_newTeamAddr);

 }

 function UpdateTeamTokenDetails(address _teamaddr,
                            uint256 _tokenamount,
                            uint256 _lockExpiryDateTime) internal
 {
       //check if Team is Active
       require(CheckIfTeamActive(_teamaddr) == true);
      teamDistribution storage teamDetails = teamDistributionDetails[_teamaddr];
 
      teamDetails.tokenamount += _tokenamount;
      teamDetails.lockexpiry = _lockExpiryDateTime;
  
 }

 function RemoveTeamFromFurtherInvestment(address _newTeamAddr) public onlyTokenOwner  
 {
    teamDistribution storage teamDetails = teamDistributionDetails[_newTeamAddr];
    teamDetails.teamActiveInvestor = false;

 }



 function TotalTeamnvestor() public view returns(uint256) 
 {
   return teamTokenDetailsAddr.length;
  
 }

//check if Team Removed 
 function CheckIfTeamActive(address _teamAddr) view internal returns(bool)
 {

  teamDistribution storage teamDetails = teamDistributionDetails[_teamAddr];

  if(teamDetails.teamActiveInvestor == true)
  {
      return true;
  }
  return false;

 }

 //check Amount with Advisor
 function CheckTeamTokenAmount(address _newTeamAddr) view public returns(uint256)
 {

  teamDistribution storage teamDetails = teamDistributionDetails[_newTeamAddr];
        return teamDetails.tokenamount;

 }

}
