pragma solidity ^0.4.25;

contract BrightCoinTokenConfig
{

    //Token Details  
  string public constant symbol = "BDLR"; // This is token symbol
  string public constant name = "BDollar"; // this is token name
  uint256 public constant decimals = 18; // decimal digit for token price calculation
  string public constant version = "1.0";

  uint256 public constant initialSupply = 3000000000;

   //For Presales Only 
    uint256  public constant maxCoinSoldDuringPresale = 400000000;
    uint256  public constant BonusAmountPreSale = 0; //To be calculated from outside
    uint8    public constant Discount = 0; // to be calculated from outside

     //PreSale Start & End Dates 
    uint256 internal ICOstartDate = 1561161600; //22/06/2019 00:00 UTC
    uint256 internal ICOendDate =  1569193200;   //22/09/2019 23:00 UTC

     //Presale Maximum and Minmum Contributions
    uint256  internal MinimumContribution = 0.0 ether;
    uint256  internal MaximumContribution = 0.0 ether;

    //purchase rate can be changed by the Owner
     uint256 public purchaseRate = 0;

    enum BrightCoinICOType { RegD, RegS, RegDRegS, Utility }
    uint8 public constant ICOType = uint8(BrightCoinICOType.Utility);   //0 for RegD , 1 for RegS and 2 for RedDRegS and 3 means utility ICO

   uint256 public constant InitialFounderToken = 0;
   uint256 internal constant InitialAllocatedTeamToken = 0;  // Token token allocated for Team distribution
   uint256 internal constant InitialAllocatedAdvisorToken = 0;


   uint internal icoSoftcap = 0; //Minimum Eather to Reach
   uint internal icoHardcap = 2400000000;

    //Investment storage address
  address public constant FundDepositAddress = 0x00; //Should be taken from Script 

   //Company Holdings
 address public constant CompanyHoldingAddress = 0x5E26720Aae2c08cC6E232e5f9719860562964271; //company Holding adddress
 uint256 public constant InitialCompanyHoldingValue = 600000000;// Value to be updated via Script

//Bounty Token Distribution
uint256 public constant totalBountyAllocated = 0;
address public  constant BountyTokenHolder = 0x00; //This address own the token and finally transfer



}
