pragma solidity 0.5.17;

contract Ownable {

// A list of owners which will be saved as a list here, 
// and the values are the owner’s names. 


  string [] ownerName;  
  address newOwner; // temp for confirm;
  mapping (address=>bool) owners;
  mapping (address=>uint256) ownerToProfile;
  address owner;

// all events will be saved as log files
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event AddOwner(address newOwner,string name);
  event RemoveOwner(address owner);
  /**
   * @dev Ownable constructor , initializes sender’s account and 
   * set as owner according to default value according to contract
   *
   */

   // this function will be executed during initial load and will keep the smart contract creator (msg.sender) as Owner
   // and also saved in Owners. This smart contract creator/owner is 
   // Mr. Samret Wajanasathian CTO of Shuttle One Pte Ltd (https://www.shuttle.one)

   constructor() public {
    owner = msg.sender;
    owners[msg.sender] = true;
    uint256 idx = ownerName.push("SAMRET WAJANASATHIAN");
    ownerToProfile[msg.sender] = idx;

  }

// // function to check whether the given address is either Wallet address or Contract Address

//   function isContract(address _addr) internal view returns(bool){
//      uint256 length;
//      assembly{
//       length := extcodesize(_addr)
//      }
//      if(length > 0){
//       return true;
//     }
//     else {
//       return false;
//     }

//   }

// function to check if the executor is the owner? This to ensure that only the person 
// who has right to execute/call the function has the permission to do so.
  modifier onlyOwner(){
    require(msg.sender == owner,"SZO/ERROR-not-owner");
    _;
  }

// This function has only one Owner. The ownership can be transferrable and only
//  the current Owner will only be  able to execute this function.
//  Onwer can be Contract address
  function transferOwnership(address  _newOwner, string memory newOwnerName) public onlyOwner{
    
    uint256 idx;
    if(ownerToProfile[_newOwner] == 0)
    {
    	idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }


    emit OwnershipTransferred(owner,_newOwner);
    newOwner = _newOwner;

  }
  
  // Function to confirm New Owner can execute
  function newOwnerConfirm() public returns(bool){
        if(newOwner == msg.sender)
        {
            owner = newOwner;
            newOwner = address(0);
            return true;
        }
        return false;
  }

// Function to check if the person is listed in a group of Owners and determine
// if the person has the any permissions in this smart contract such as Exec permission.
  
  modifier onlyOwners(){
    require(owners[msg.sender] == true);
    _;
  }

// Function to add Owner into a list. The person who wanted to add a new owner into this list but be an existing
// member of the Owners list. The log will be saved and can be traced / monitor who’s called this function.
  
  function addOwner(address _newOwner,string memory newOwnerName) public onlyOwners{
    require(owners[_newOwner] == false,"SZO/ERROR-already-owner");
    require(newOwner != msg.sender,"SZO/ERROR-same-owner-add");
    if(ownerToProfile[_newOwner] == 0)
    {
    	uint256 idx = ownerName.push(newOwnerName);
    	ownerToProfile[_newOwner] = idx;
    }
    owners[_newOwner] = true;
    emit AddOwner(_newOwner,newOwnerName);
  }

// Function to remove the Owner from the Owners list. The person who wanted to remove any owner from Owners
// List must be an existing member of the Owners List. The owner cannot evict himself from the Owners
// List by his own, this is to ensure that there is at least one Owner of this ShuttleOne Smart Contract.
// This ShuttleOne Smart Contract will become useless if there is no owner at all.

  function removeOwner(address _owner) public onlyOwners{
    require(_owner != msg.sender,"SZO/ERROR-remove-yourself");  // can't remove your self
    owners[_owner] = false;
    emit RemoveOwner(_owner);
  }
// this function is to check of the given address is allowed to call/execute the particular function
// return true if the given address has right to execute the function.
// for transparency purpose, anyone can use this to trace/monitor the behaviors of this ShuttleOne smart contract.

  function isOwner(address _owner) public view returns(bool){
    return owners[_owner];
  }

// Function to check who’s executed the functions of smart contract. This returns the name of 
// Owner and this give transparency of whose actions on this ShuttleOne Smart Contract. 

  function getOwnerName(address ownerAddr) public view returns(string memory){
  	require(ownerToProfile[ownerAddr] > 0,"SZO/ERROR-NOT-OWNER-ADDRESS");
  	return ownerName[ownerToProfile[ownerAddr] - 1];
  }
}


contract SZO {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
  
	   function createKYCData(bytes32 _KycData1, bytes32 _kycData2,address  _wallet) public returns(uint256);
}

contract ShuttleLockToken is  Ownable {
     SZO public szoToken;
     uint256 public version = 1;
     address public genesis;
     address public dev;
     address public founder;
     address public seedinvester;
      
     uint256  genesisQuota = 37000000 ether;
     uint256  devQuota     = 23000000 ether;
     uint256  founderQuota = 23000000 ether;
     uint256  seedQuota    = 13800000 ether;
     
       constructor() public {
           
       }
       
       function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
             bytes memory tempEmptyStringTest = bytes(source);
            if (tempEmptyStringTest.length == 0) {
                return 0x0;
             }

            assembly {
                 result := mload(add(source, 32))
            }
        }
       
       function setSZOContract(address _addr) public onlyOwners{
           
           szoToken = SZO(_addr);
       }
       
       function tranferToGenesis(address _addr) public onlyOwners returns(bool){
           require(genesis == address(0),"ERROR Already Send to Genesis");
           genesis = _addr;
           szoToken.transfer(genesis,genesisQuota);
           szoToken.createKYCData(stringToBytes32("Genesis Address"),stringToBytes32("NONE"),genesis);
           return true;
       }
       
        function tranferToDev(address _addr) public onlyOwners returns(bool){
           require(dev == address(0),"ERROR Already Send to Developer");
           dev = _addr;
           szoToken.transfer(dev,devQuota);
           szoToken.createKYCData(stringToBytes32("Developer Address"),stringToBytes32("NONE"),dev);
           return true;
       }
       
        function tranferToFounder(address _addr) public onlyOwners returns(bool){
           require(founder == address(0),"ERROR Already Send to Founder");
           founder = _addr;
           szoToken.transfer(founder,founderQuota);
           szoToken.createKYCData(stringToBytes32("Founder Address"),stringToBytes32("NONE"),founder);
           return true;
       }
       
       function transferToSeed(address _addr) public onlyOwners returns(bool){
           require(seedinvester == address(0),"ERROR Already Send to SEED Investor");
           seedinvester = _addr;
           szoToken.transfer(seedinvester,seedQuota);
           szoToken.createKYCData(stringToBytes32("SEED Address"),stringToBytes32("NONE"),seedinvester);
           return true;
       }


      function transfer(address _to,uint256 _amount) public onlyOwners returns(bool){
          // Emegency Call just in case have problem
          return szoToken.transfer(_to,_amount);
      }

      // 96.8M Token (GENESIS USERS = 37M,DEV = 23M,FOUNDER = 23M,EQUITY SEED A INVESTORS = 13.8M)
}
