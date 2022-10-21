pragma solidity ^0.5.0;

interface OrganizationFactoryInterface {
    function createOrganization(address lotFactory, address owner, bool isActive) external returns (address);
}
