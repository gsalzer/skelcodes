pragma solidity ^0.5.0;

contract OrganizationInterface {
    function hasPermissions(address permittee, uint256 permission) public view returns (bool);
}

