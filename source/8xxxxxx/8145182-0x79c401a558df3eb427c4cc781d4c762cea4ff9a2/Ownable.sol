pragma solidity 0.5.0;

contract Ownable {
   address payable public owner;

   event OwnershipTransferred(address indexed _from, address indexed _to);

   constructor() public {
       owner = msg.sender;
   }

   modifier onlyOwner {
       require(msg.sender == owner);
       _;
   }

   function transferOwnership(address payable _newOwner) public onlyOwner {
       owner = _newOwner;
   }
}

