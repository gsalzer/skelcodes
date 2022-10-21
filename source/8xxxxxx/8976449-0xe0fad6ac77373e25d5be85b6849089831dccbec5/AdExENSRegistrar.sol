pragma solidity ^0.5.6;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}

contract AdExENSRegistrar {
    ENS ens;
    bytes32 rootNode;

    constructor(ENS ensAddr, bytes32 node) public {
        ens = ensAddr;
        rootNode = node;
    }

    function register(bytes32 label, address owner) public {
        bytes32 subdomainNode = keccak256(abi.encodePacked(rootNode, label));
        address currentOwner = ens.owner(subdomainNode);
        require(currentOwner == address(0x0) || currentOwner == msg.sender);
        ens.setSubnodeOwner(rootNode, label, owner);
    }
}
