pragma solidity 0.6.0;


//Supermanager
contract RoleManageContract {
    
    address public _owner;
    address public _burnAddresser;

    constructor() public { 
        _owner = msg.sender; 
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }
 
     modifier onlyBurner() {
        require(msg.sender == _burnAddresser);
        _;
    }
  
    function transferBurnship(address newBurn) public onlyOwner {
        if (newBurn != address(0)) {
            _burnAddresser = newBurn;
        }
    }
    
    
}

