pragma solidity ^0.4.25;
//pragma experimental "v0.5.0";

import "./BrightCoinTokenOwner_ICO.sol";
import "./BrightCoinERC20ContractInterface_ICO.sol";
import "./BrightCoinTokenSaleType_ICO.sol";
//import "./BrightCoinAdminTokenDistributionDetails.sol";
import "./SafeMath.sol";
import "./BrightCoinInvestorTokenLock_ICO.sol";





contract BrightCoinERC20 is BrightCoinTokenPreSaleDetails,
                            BrightCoinTokenMainSaleDetails,
                        //   BrightCoinAdminTokenDistributionDetails,
                            BrightCoinInvestorTokenLock
                           
                          
                         
                            
{
  using SafeMath for uint;


 event Transfer(address indexed from, address indexed _to, uint256 _value);
  event Approval(address indexed owner, address indexed _spender, uint256 _value);
   // Event called when presale is done
  event PresaleFinalized(uint tokens);
  event ICOSoftCapReached(string softcap);
  event ICOSoftUnsuccessFull(uint256 TokenSold,string str);
  event Burn(address addr, uint256 tokens);
  event Mint(address target, uint256 mintedAmount);
  
 
  bool  internal pauseICO = false; 
  uint8 internal saleIndex = 0; //Default Sale Index as zero

//Token Supply Details
  uint256 public totalSupply; //Need to set at constructor level
  uint256 private  BountyDistriuted = 0;
  uint256 internal CompanyHoldingValue = 0;
   mapping(address => uint256)CompanyHoldingBalances;
   address internal custodianaddress;
 

  //Purchase Rate
  function setPurchaseRate(uint newRate) public onlyTokenOwner {
        require(purchaseRate != newRate);
        purchaseRate = newRate;
    }
 
 //ICO SoftCap & HardCap
 /*
    Soft cap is the minimal amount required by your project, to make it viable, in order to continue. If you do not reach that amount during your ICO then you should allow your investors to refund their money using a push/ pull mechanism.
 */
 

   function ChangeSoftCap(uint _newSoftcap) public onlyTokenOwner {
        require(icoSoftcap != _newSoftcap);
       // require(_newSoftcap <= totalSupply);
       require(icoSoftcap <= (balances[owner()].add(balances[custodianaddress])));
        icoSoftcap = _newSoftcap;
      
    }
    function changeHardCapLimit(uint256 _newHardcap) public onlyTokenOwner {
       
        require(icoHardcap != _newHardcap);
        require(_newHardcap <= (balances[owner()].add(balances[custodianaddress])));
       // require(_newHardcap <= totalSupply);
        icoHardcap = _newHardcap;
      
    }


    function GetSoftcap() public  view   returns(uint256) {

      return icoSoftcap;
    }

     function GetHardcap() public   view  returns(uint256) {

      return icoHardcap;
    }

    //Check if softcap reached
    function CheckIfSoftcapAchived() public   view returns(bool)
    {

        uint256 ownerbal = balances[owner()]; 
    
        uint256 custodianbal = balances[custodianaddress];
       uint tokenSold = totalSupply.sub(ownerbal.add(custodianbal));

        if (tokenSold > icoSoftcap)
            return true;
        else 
            return false;  
        
    }

    //check if HARD Cap Achived
    function CheckIfHardcapAchived(uint256 _tokens)  public view returns(bool)
    {
        uint256 ownerbal = balances[owner()]; 
        uint256 custodianbal = balances[custodianaddress];
      uint tokenSold = totalSupply.sub(ownerbal.add(custodianbal));
      require(tokenSold <= icoHardcap);
      require(tokenSold.add(_tokens) <=icoHardcap);
      return true;

    }

 
    function setSalePeriodIndex(uint8 _index) public onlyTokenOwner  
    {
        require(_index >0); //To set minimum Sale Period Index
        saleIndex = _index;
        
    }
    
     function getSalePeriodIndex()  public view  returns(uint8)
    {
        return saleIndex;
        
    }
  
  
 /* function ChangeFundDepositAddress(address _newFundDepositAddress) public onlyTokenOwner  {
    require(_newFundDepositAddress != address(0x0));
    require( FundDepositAddress != _newFundDepositAddress );
    //FundDepositAddress = _newFundDepositAddress;
  }
  */
  

//option for Minting more token 
bool public MintMoreTokens  = false;
function UpdateTokenMintingOption(bool _mintingOption) public onlyTokenOwner  {
  
  MintMoreTokens = _mintingOption;
}


 /////////////////////////////////////////////////   

 
 ////////////////////////////////////////
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;

  
  
 //////////////////////////////////////////
  
 
  constructor () public{

   totalSupply = initialSupply*(10**uint256(decimals));

   //TotalAllocatedTeamToken = InitialAllocatedTeamToken*(10**uint256(decimals));
  // TotalAllocatedFounder = InitialFounderToken*(10**uint256(decimals));
 //  TotalAllocatedAdvisorToken = InitialAllocatedAdvisorToken*(10**uint256(decimals));
  CompanyHoldingValue = InitialCompanyHoldingValue*(10**uint256(decimals));
  // BountyAllocated = totalBountyAllocated*(10**uint256(decimals));
   

   icoHardcap = icoHardcap.mul(10**uint256(decimals));
   icoSoftcap = icoSoftcap.mul(10**uint256(decimals));
   
   balances[msg.sender] = totalSupply;
  emit Transfer(address(0), msg.sender, totalSupply);
   
 // FounderBalances[msg.sender] = TotalAllocatedFounder;
 // AdvisorBalances[msg.sender] = TotalAllocatedAdvisorToken;
//  TeamBalances[msg.sender] = TotalAllocatedTeamToken;
  CompanyHoldingBalances[msg.sender] = CompanyHoldingValue;
  //BountyBalances[msg.sender]  = BountyAllocated;
 // balances[BountyTokenHolder] = BountyAllocated;
   
  
  // BountyDistriuted = 0;
 
  }

 

 // This function returns remaininig token
  function balanceOf(address _who) public constant returns (uint256) {
      return balances[_who];
  }

//Function Total Supply
function totalSupply() public constant returns (uint256) {
      return totalSupply;
  }

function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
}
    
   
    /// @notice Will Transfer tokens from current address to receipient address.
    /// @param _from  addresses to send token.
    /// @param _tokens amount of token to be transferred.
   /* function internaltransfer1(address _to, address _from, uint _tokens) internal returns (bool) {
  
     // Prevent transfer to 0x0 address. 
   require(_to != 0x0);
    require (_tokens > 0);
    require (_from != _to);
   require(balances[_from] >= _tokens);
   require(balances[_to] + _tokens > balances[_to]);
    balances[_from] = balances[_from].sub(_tokens);
    balances[_to] = balances[_to].add(_tokens);
    return true;
   }
   */
   
   /// @notice Will Transfer tokens from current address to receipient address.
    /// @param _recipient  addresses to send token.
    /// @param _tokens amount of token to be transferred.
    function internaltransfer(address _from, address _to, uint _tokens) internal returns (bool) {
  
     // Prevent transfer to 0x0 address. 
    require(_to != 0x0);
    require (_tokens > 0);
    require (_from != _to);
   require(balances[_from] >= _tokens);
   require(balances[_to] + _tokens > balances[_to]);
    balances[_from] = balances[_from].sub(_tokens);
    balances[_to] = balances[_to].add(_tokens);
 
    return true;
   }
   

    /// @notice Will cause a certain `_value` of coins minted for `_to`.
    /// @param _to The address that will receive the coin.
    /// @param _value The amount of coin they will receive.
    function mint(address _to, uint _value) public onlyTokenOwner  {
       // assuming you have a contract owner
        mintToken(_to, _value);
    }

/*
    /// @notice Will allow multiple minting within a single call to save gas.
    /// @param recipients A list of addresses to mint for.
    /// @param _values The list of values for each respective `_to` address.
    function airdropMinting(address[] recipients, uint256[] _values) public onlyTokenOwner  {
        // assuming you have a contract owner
        require(recipients.length == _values.length);
        for (uint i = 0; i < recipients.length; i++) {

            mintToken(recipients[i], _values[i]);
        }
    }
    */

    /// Internal method shared by `mint()` and `airdropMinting()`.
    function mintToken(address _to, uint256 _value) internal {

   
        balances[_to]  = balances[_to].add(_value);
        totalSupply =  totalSupply.add(_value); 
        require(balances[_to] >= _value && totalSupply >= _value); // overflow checks
        emit  Mint(_to, _value);
    } 

    /// @notice it will burn all the token passed as parameter.
    /// @param _value Value of token to be burnt
   function burn(uint256 _value) public onlyTokenOwner  {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(burner, _value);
   }


   //Owner of ICO can anytime Stop the ICO post that no any transaction will happen
   function pauseICOtransaction(bool _status) public onlyTokenOwner  {

    pauseICO = _status;
   }

//Check if token is available for further Distribution to Admin
/* function InterTransferToAdmin(address _addr,
                     uint256 _tokenAmount,
                     uint8 _adminType )   internal  returns(bool)
 {
     

     if(_adminType == uint8(BrightCoinAdminType.Founder))
    {
        require(_tokenAmount <= FounderBalances[msg.sender]);
        // balances[_addr] = balances[_addr].add(_tokenAmount);
        internaltransfer(msg.sender,_addr,_tokenAmount);
         FounderBalances[msg.sender] = FounderBalances[msg.sender].sub(_tokenAmount);
        // emit Transfer(msg.sender, addr, TokenAmount);
      return true;
    }
    else if (_adminType == uint8(BrightCoinAdminType.Advisor))
    {
      require(_tokenAmount <= AdvisorBalances[msg.sender]);
      //balances[_addr] = balances[_addr].add(_tokenAmount);
       internaltransfer(msg.sender,_addr,_tokenAmount);
      AdvisorBalances[msg.sender] = AdvisorBalances[msg.sender].sub(_tokenAmount);
     // emit Transfer(msg.sender, addr, TokenAmount);
      return true;
    }
    else if(_adminType == uint8(BrightCoinAdminType.Team))
    {
      require(_tokenAmount <= TeamBalances[msg.sender]);
      //balances[_addr] = balances[_addr].add(_tokenAmount);
       internaltransfer(msg.sender,_addr,_tokenAmount);
      TeamBalances[msg.sender] = TeamBalances[msg.sender].sub(_tokenAmount);
     // emit Transfer(msg.sender, addr, TokenAmount);
      return true;

    }  
    
    
 }
 */
    //Check if token is available for further Distribution to Advisor
 function InternalTransferfrom(address _from , address _addr, uint256 _tokenamount)  internal returns(bool)
 {
     
        require(allowed[owner()][_from] >= _tokenamount);
        require(internaltransfer(_from, _addr, _tokenamount) == true);
        allowed[owner()][_from] = allowed[owner()][_from].sub(_tokenamount);
       
       return true;
 }  
 
function transferownership(address _newOwner) public onlyTokenOwner 
 {
     
     require(_newOwner != 0x0);
    balances[_newOwner] =  balances[_newOwner].add(balances[msg.sender]);
     //To avoid reentrency 
   balances[msg.sender] = 0;
   emit Transfer(msg.sender, _newOwner, balances[_newOwner]);
   
   
  //FounderBalances[_newOwner] = FounderBalances[_newOwner].add(FounderBalances[msg.sender]);
  //AdvisorBalances[_newOwner] = AdvisorBalances[_newOwner].add(AdvisorBalances[msg.sender]);
 // TeamBalances[_newOwner] = TeamBalances[_newOwner].add(TeamBalances[msg.sender]);
 CompanyHoldingBalances[_newOwner] = CompanyHoldingBalances[_newOwner].add(CompanyHoldingBalances[msg.sender]);

    //To avoid reentrency 
 // balances[msg.sender] = 0;
//  FounderBalances[msg.sender] = 0;
 // AdvisorBalances[msg.sender] = 0;
 // TeamBalances[msg.sender] = 0;
  
   transferOwnership(_newOwner); // Transfer Ownership
     
     
 }



}
