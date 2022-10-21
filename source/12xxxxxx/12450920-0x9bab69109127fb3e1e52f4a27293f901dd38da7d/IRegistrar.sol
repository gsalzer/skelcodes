// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./IERC721Enumerable.sol";

interface IRegistrar is IERC721Enumerable {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Metadata {
        string uri;
        Signature signature;
    }

    event OwnerChanged(bytes32 indexed label, address indexed oldOwner, address indexed newOwner);
    event DomainConfigured(bytes32 indexed label);
    event DomainUnlisted(bytes32 indexed label);
    event NewRegistration(bytes32 indexed label, string subdomain, address indexed owner, uint price);
    event RentPaid(bytes32 indexed label, string subdomain, uint amount, uint expirationDate);

    // InterfaceID of these four methods is 0xc1b15f5a
    function query(bytes32 label, string calldata subdomain) external view returns (string memory domain, uint signupFee, uint rent);
    function register(bytes32 label, string calldata subdomain, address owner, Metadata memory metadata) external payable;

    function rentDue(bytes32 label, string calldata subdomain) external view returns (uint timestamp);
    function payRent(bytes32 label, string calldata subdomain) external payable;
}

