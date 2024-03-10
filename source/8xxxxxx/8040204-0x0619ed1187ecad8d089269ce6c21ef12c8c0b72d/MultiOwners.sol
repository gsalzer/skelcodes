pragma solidity 0.5.8;


contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;

    constructor() public {
        owners[msg.sender] = true;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() view public returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function checkOwner(address maybe_owner) view public returns (bool) {
        return owners[maybe_owner] ? true : false;
    }


    function grant(address _owner) public onlyOwner {
        owners[_owner] = true;
        emit AccessGrant(_owner);
    }

    function revoke(address _owner) public onlyOwner {
        require(msg.sender != _owner);
        owners[_owner] = false;
        emit AccessRevoke(_owner);
    }
}

