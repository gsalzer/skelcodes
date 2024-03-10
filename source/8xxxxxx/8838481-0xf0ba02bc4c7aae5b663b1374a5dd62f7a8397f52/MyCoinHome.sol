pragma solidity ^0.5.12;
contract MyCoinHome {

      mapping(string => bool) private restrictedUsernames;
      
      mapping(string=> string) usernameToIpfsHash;
      mapping(string=>address)  usernameToOwner;
      mapping(address=> string) ownerToUsername;

      address public admin;


      string[] restrictedNames = ["admin","message","error","notice","home","contact","root"];


    constructor() public {

        admin = msg.sender;

      for(uint i=0;i<7;i++){
            restrictedUsernames[restrictedNames[i]]=true;
        }
    }


//   ************************ STATUS CHECK **********************************************
    function hasUser(address userAddress) public view returns(bool) {
        if(keccak256(abi.encodePacked(ownerToUsername[userAddress])) == keccak256 ("")){
            return false;
        }
        return true;
      }

    function usernameTaken(string memory _username) public view returns(bool) {
        if(usernameToOwner[_username] == address(0)){
            return false;
        }
        return true;

      }

    //   ************************** UTILITY FUNCTIONS *****************************************
      function createUser(string  memory username, string memory ipfsHash) public  {
        require(!hasUser(msg.sender), "User already registered");
        require(!usernameTaken(username), "Username has been taken");
        require(!(restrictedUsernames[username]==true), "This username cannot be registered");
        bytes memory tempString = bytes(username); 
        require(tempString.length !=0, "Cannot register an empty string");
        usernameToIpfsHash[username] = ipfsHash;
        usernameToOwner[username] = msg.sender;
        ownerToUsername[msg.sender] = username;
      }
      
      function getOwner(string memory username) view public returns(address){
          return usernameToOwner[username];
      }
      
      
      function updateUserIpfs(string memory ipfsHash) public  {
        require(hasUser(msg.sender), "You need to have an account to edit your profile");
        usernameToIpfsHash[getUsernameByAddress(msg.sender)] = ipfsHash;
      }

      function getIpfsHashByUsername(string memory username) public view returns(string memory ipfsHash){
          return usernameToIpfsHash[username];
      }

      function getUsernameByAddress(address _address) public view returns( string memory username){
            return ownerToUsername[_address];
      }


    //   ************************************* MODIFIERS *************************************

      modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
       }


}
