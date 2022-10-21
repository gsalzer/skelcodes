// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../ERC20Escrow.sol";
import "../vendor/openzeppelin/SafeMath.sol";
import "../vendor/openzeppelin/ECDSA.sol";
import "../vendor/openzeppelin/SafeERC20.sol";
import "../vendor/openzeppelin/IERC20.sol";

contract ERC20EscrowDeployerFacet {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    AppStorage s;

    bytes32 constant NAMESPACE = keccak256("com.escaroo.erc20.escrow.deployer");

    struct ERC20EscrowConfig {
        bytes id;
        IERC20 token;
        address mediator;
        address affiliate;
        address buyer;
        address seller;
        uint256 amount;
        uint256 fee;
        uint256 commission;
    }

    modifier onlyWithValidERC20EscrowSig(
        ERC20EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    ) {
        bytes32 deployHash = getERC20EscrowDeployHash(_cfg, _expiry);
        require(deployHash.toEthSignedMessageHash().recover(_signature) == LibDiamond.contractOwner(), "Invalid deployment signature.");
        _;
    }

    event EscrowDeployed(bytes32 indexed id, address escrowAddr);

    function getERC20EscrowDeployHash(
        ERC20EscrowConfig memory _cfg,
        uint32 _expiry
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                _cfg.id,
                _cfg.token,
                _cfg.buyer,
                _cfg.seller,
                _cfg.amount,
                _cfg.fee,
                _expiry
            )
        );
    }

    function createNewERC20Escrow(
        ERC20EscrowConfig memory _cfg
    )
        internal
        returns (ERC20Escrow)
    {
        bytes32 escrowID = keccak256(abi.encodePacked(_cfg.id, _cfg.buyer, _cfg.seller, _cfg.amount, _cfg.fee));
        require(
            s.escrows[escrowID] == address(0),
            "Escrow already exists!"
        );
        ERC20Escrow escrow = new ERC20Escrow(
            escrowID,
            _cfg.token,
            address(uint160(LibDiamond.contractOwner())),
            _cfg.buyer,
            _cfg.seller,
            _cfg.mediator,
            _cfg.affiliate,
            _cfg.amount,
            _cfg.fee,
            _cfg.commission
        );
        s.escrows[escrowID] = address(escrow);
        emit EscrowDeployed(escrowID, address(escrow));
        return escrow;
    }

    function deployERC20Escrow(
        ERC20EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    )
        public
        onlyWithValidERC20EscrowSig(_cfg, _expiry, _signature)
        returns (ERC20Escrow)
    {
        /* solium-disable-next-line */
        require(block.timestamp < _expiry, "Deployment signature expired.");
        ERC20Escrow escrow = createNewERC20Escrow(_cfg);
        return escrow;
    }

    function deployAndFundERC20Escrow(
        ERC20EscrowConfig memory _cfg,
        uint32 _expiry,
        bytes memory _signature
    )
        public
        onlyWithValidERC20EscrowSig(_cfg, _expiry, _signature)
        returns (ERC20Escrow)
    {
        /* solium-disable-next-line */
        require(block.timestamp < _expiry, "Deployment signature expired.");
        ERC20Escrow escrow = createNewERC20Escrow(_cfg);
        IERC20(_cfg.token).safeTransferFrom(msg.sender, address(this), _cfg.amount);
        IERC20(_cfg.token).safeApprove(address(escrow), _cfg.amount);
        escrow.deposit();
        return escrow;
    }
}
