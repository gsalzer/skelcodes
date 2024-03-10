pragma solidity ^0.5.0;

import "./OfferingRegistry.sol";
import "./Offering.sol";
import "./ENS.sol";
import "./HashRegistrar.sol";

/**
 * @title OfferingFactory
 * @dev Base contract factory for creating new offerings
 */

contract OfferingFactory {

    ENS public ens;
    OfferingRegistry public offeringRegistry;

    // Hardcoded namehash of "eth"
    bytes32 public constant rootNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    constructor (
        ENS _ens,
        OfferingRegistry _offeringRegistry
    ) public {
        ens = _ens;
        offeringRegistry = _offeringRegistry;
    }

    /**
    * @dev Deploys new BuyNow offering and registers it to OfferingRegistry
    * @param name string Plaintext ENS name
    * @param price uint The price of the offering
    */
    function createOffering(
        bytes32 node,
        string memory name,
        bytes32 labelHash,
        uint price
    ) public {
        Offering newOffering = new Offering(ens, offeringRegistry, offeringRegistry.emergencyMultisig());
        uint8 version = 1;

        newOffering.construct(
            node,
            name,
            labelHash,
            msg.sender,
            version,
            price
        );

        registerOffering(node, labelHash, address(newOffering), version);
    }

    /**
    * @dev Registers new offering to OfferingRegistry, clears offering requests for this ENS node
    * Must check if creator of offering is actual owner of ENS name and for top level names also deed owner
    * @param node bytes32 ENS node
    * @param labelHash bytes32 ENS labelhash
    * @param newOffering address The address of new offering
    * @param version uint The version of offering contract
    */
    function registerOffering(bytes32 node, bytes32 labelHash, address newOffering, uint version)
        internal
    {
        require(ens.owner(node) == msg.sender);
        if (node == keccak256(abi.encodePacked(rootNode, labelHash))) {
            address deed;
            (,deed,,,) = HashRegistrar(ens.owner(rootNode)).entries(labelHash);
            require(Deed(deed).owner() == msg.sender);
        }

        offeringRegistry.addOffering(newOffering, node, msg.sender, version);
    }
}
