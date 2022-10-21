pragma solidity ^0.5.0;

contract LotInterface {
    function getOrganization() public view returns (address);
    function allocateSupply(address _lotAddress, uint32 _quantity) public;
}

