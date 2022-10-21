pragma solidity 0.5.4;

contract Owned {

address payable  owner;
address payable newOwner;


constructor() public{
    owner = msg.sender;
}


function changeOwner(address payable _newOwner) public onlyOwner {

    newOwner = _newOwner;

}

function acceptOwnership() public{
    if (msg.sender == newOwner) {
        owner = newOwner;
        newOwner = address(0);
    }
}

modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}
}

