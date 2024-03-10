// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../Escrow.sol";
import "../vendor/openzeppelin/SafeMath.sol";
import "../vendor/openzeppelin/ECDSA.sol";

contract EscrowDeployerFacet {
    using ECDSA for bytes32;
    using SafeMath for uint256;

    AppStorage s;

    bytes32 constant NAMESPACE = keccak256("com.escaroo.eth.escrow.deployer");

    struct EscrowConfig {
        bytes id;
        address payable mediator;
        address payable affiliate;
        address payable buyer;
        address payable seller;
        uint256 amount;
        uint256 fee;
        uint256 commission;
    }

    modifier onlyWithValidEscrowSig(
        EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    ) {
        bytes32 deployHash = getEscrowDeployHash(_cfg, _expiry);
        require(deployHash.toEthSignedMessageHash().recover(_signature) == LibDiamond.contractOwner(), "Invalid deployment signature.");
        _;
    }

    event EscrowDeployed(bytes32 indexed id, address escrowAddr);

    function getEscrowDeployHash(
        EscrowConfig memory _cfg,
        uint32 _expiry
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _cfg.id,
                _cfg.mediator,
                _cfg.buyer,
                _cfg.seller,
                _cfg.amount,
                _cfg.fee,
                _expiry
            )
        );
    }

    function createNewEscrow(
        EscrowConfig memory _cfg
    )
        internal
        returns (Escrow)
    {
        bytes32 escrowID = keccak256(abi.encodePacked(_cfg.id, _cfg.buyer, _cfg.seller, _cfg.amount, _cfg.fee));
        require(s.escrows[escrowID] == address(0), "Escrow already exists!");
        Escrow escrow = new Escrow(escrowID, address(uint160(LibDiamond.contractOwner())), _cfg.buyer, _cfg.seller, _cfg.mediator, _cfg.affiliate, _cfg.amount, _cfg.fee, _cfg.commission);
        s.escrows[escrowID] = address(escrow);
        emit EscrowDeployed(escrowID, address(escrow));
        return escrow;
    }

    function deployEscrow(
        EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    )
        public
        onlyWithValidEscrowSig(_cfg, _expiry, _signature)
        returns (Escrow)
    {
        /* solium-disable-next-line */
        require(block.timestamp < _expiry, "Deployment signature expired.");
        Escrow escrow = createNewEscrow(_cfg);
        return escrow;
    }

    function deployAndFundEscrow(
        EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    )
        public
        payable
        onlyWithValidEscrowSig(_cfg, _expiry, _signature)
        returns (Escrow)
    {
        /* solium-disable-next-line */
        require(block.timestamp < _expiry, "Deployment signature expired.");
        require(msg.value == _cfg.amount, "Wrong ether amount.");
        Escrow escrow = createNewEscrow(_cfg);
        escrow.deposit{value: msg.value}();
        return escrow;
    }
}
