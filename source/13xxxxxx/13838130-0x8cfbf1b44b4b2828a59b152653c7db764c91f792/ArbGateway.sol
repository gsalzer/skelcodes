// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./Outbox.sol";
import "./Inbox.sol";
import "./ArbSys.sol";
import "./Initializable.sol";

interface HungryBunz is IERC721 {
    function serializeAtts(uint16 tokenId) external view returns (bytes16);
    function serializeStats(uint16 tokenId) external view returns (bytes16);
    function writeSerializedAtts(uint16 tokenId, bytes16 newAtts) external;
    function writeSerializedStats(uint16 tokenId, bytes16 newStats) external;
    function setInactiveOnThisChain(uint16 tokenId) external;
    function setActiveOnThisChain(uint16 tokenId, bytes memory metadata, address sender) external;
    function applicationOwnerOf(uint256 tokenId) external view returns (address);
}

interface INom {
    function burn(address account, uint256 amount) external;
    function applicationMint(address to, uint256 amount) external;
}

interface IArbPartner {
    function synchronizeAndRelease(uint16,address,bytes memory) external;
    function receiveNom(address initiatedBy, uint256 quantity) external;
}

contract ArbGateway is Ownable, Initializable {
    //******************************************************
    //CRITICAL CONTRACT PARAMETERS
    //******************************************************
    //Pausable library is simple enough to integrate into this contract
    bool public paused = false;

    uint8 _layer;
    address _signer;
    address _arbPartner;
    IArbPartner _arbPartnerInterface;
    IInbox _inbox; //Inbox for L1
    IOutbox _outbox; //Outbox for L2
    HungryBunz _hbContract; //Layer-local main contract
    INom _nom; //Layer-local Nom contract
    ArbSys _ArbSys = ArbSys(address(100)); //ArbSys address never changes!
    
    event receivedMessageFromL1(address sentBy, uint16 tokenId);
    
    //******************************************************
    //CONTRACT CONSTRUCTOR
    //******************************************************
    constructor()
    {
        ownableInit();
    }

    function initGateway (
        address hbContractAddress,
        address nomContract,
        uint8 layer
    ) external initializer
    {
        require(owner() == address(0) || owner() == msg.sender,
            "No.");
        
        ownableInit();
        _layer = layer; //Set to 1 for L1, 2 for L2
        _hbContract = HungryBunz(hbContractAddress);
        _nom = INom(nomContract);

        _signer = 0xF658480075BA1158f12524409066Ca495b54b0dD;
    }
    
    function updateArbitrumInbox(address gatewayAddress) public onlyOwner {
        _inbox = IInbox(gatewayAddress);
        _outbox = IOutbox(_inbox.bridge().activeOutbox());
    }
    
    function updateArbitrumPartner(address partnerAddress) public onlyOwner {
        if (_layer == 1) {
            _arbPartner = partnerAddress;
        } else {
            address aliasedAddress = address(uint160(partnerAddress) + uint160(0x1111000000000000000000000000000000001111));
            _arbPartner = aliasedAddress;
        }
        _arbPartnerInterface = IArbPartner(_arbPartner);
    }

    //Cost of owner pausing when already paused is mild annoyance.
    //Removed extra requires
    function pause() onlyOwner public {
        paused = true;
    }
    
    function arbToEth(bytes memory synchronizationData) internal {
        _ArbSys.sendTxToL1(
            _arbPartner,
            synchronizationData
            );
        _ArbSys.sendTxToL1{value: msg.value}(msg.sender, '');
    }
    
    function ethToArb(bytes memory synchronizationData, uint256 maxBaseFee, uint256 maxGas, uint256 maxPriority) internal {
        uint256 nftTransferFees = (maxGas * maxPriority) + maxBaseFee;
        require(msg.value >= nftTransferFees + maxBaseFee, "Insufficient funds");

        _inbox.createRetryableTicketNoRefundAliasRewrite{value: nftTransferFees}(
            _arbPartner, //Destination address
            0, //Call value for remote contract call. Always 0.
            maxBaseFee, //Max submission cost
            msg.sender, //Refund excess to sender
            msg.sender, //Refund excess to sender
            maxGas, //Maximum gas units
            maxPriority, //Maximum gas price
            synchronizationData
            );
    }
    
    //Temporarily changed from payable to view for diagnostics.
    function teleportAndLock(uint16[] memory tokenIds, uint256 maxBaseFee, uint256 maxGas, uint256 maxPriority) public payable{
        require(paused == false, "Gateway paused.");

        uint256 nftTransferFees = (maxGas * maxPriority) + maxBaseFee;
        require(msg.value >= (nftTransferFees * tokenIds.length),
            "Insufficient funds");

        for(uint i = 0; i < tokenIds.length; i++) {
            //Use overriden ownerOf check to implicitly prevent
            //exploits involving teleporting a token more than
            //once, or teleporting immediately after staking.
            require(msg.sender == _hbContract.applicationOwnerOf(uint256(tokenIds[i])),
                "Cannot teleport token you don't own!");
            
            //We won't synchronize names between layers, since
            //arbitrary length strings could be exceedingly
            //expensive to synchronize across layers. This can
            //create a nuisance for future owners.
            bytes memory tokenProperties = abi.encodePacked(
                    _hbContract.serializeAtts(tokenIds[i]),
                    _hbContract.serializeStats(tokenIds[i])
                );
                
            bytes memory returndata = abi.encodeWithSelector(
                IArbPartner.synchronizeAndRelease.selector,
                tokenIds[i],
                msg.sender,
                tokenProperties
            );
            
            _hbContract.setInactiveOnThisChain(tokenIds[i]);
            
            if(_layer == 1) {
                ethToArb(returndata, maxBaseFee, maxGas, maxPriority); 
            } else {
                arbToEth(returndata);
            }
        }
    }
    
    function synchronizeAndRelease(uint16 tokenId, address initiatedBy, bytes memory properties) external {
        require(paused == false, "Gateway paused.");
        bool authorizedSender;
        if (_layer == 2) {
            if(msg.sender == _arbPartner) {
                authorizedSender = true;
            }
        } else {
            if(_outbox.l2ToL1Sender() == _arbPartner && msg.sender == address(_outbox)) {
                authorizedSender = true;
            }
        }

        require(authorizedSender, "Not from authorized sender");
        emit receivedMessageFromL1(initiatedBy, tokenId);
        _hbContract.setActiveOnThisChain(tokenId, properties, initiatedBy);
    }
    
    //Temporarily changed from payable to view for diagnostics.
    function sendNom(uint256 quantity, uint256 maxBaseFee, uint256 maxGas, uint256 maxPriority) public payable{
        require(paused == false, "Gateway paused.");

        uint256 nftTransferFees = (maxGas * maxPriority) + maxBaseFee;
        uint256 ethToDeposit = msg.value - (nftTransferFees);
        
        _inbox.depositEth{value: ethToDeposit}(maxBaseFee);
        _nom.burn(msg.sender, quantity);

        bytes memory returndata = abi.encodeWithSelector(
            IArbPartner.receiveNom.selector,
            msg.sender,
            quantity
        );
        
        if(_layer == 1) {
            ethToArb(returndata, maxBaseFee, maxGas, maxPriority); 
        } else {
            arbToEth(returndata);
        }
    }
    
    function receiveNom(address initiatedBy, uint256 quantity) external {
        require(paused == false, "Gateway paused.");
        bool authorizedSender;
        if (_layer == 2) {
            if(msg.sender == _arbPartner) {
                authorizedSender = true;
            }
        } else {
            if(_outbox.l2ToL1Sender() == _arbPartner && msg.sender == address(_outbox)) {
                authorizedSender = true;
            }
        }
        require(authorizedSender, "Not from authorized sender");
        _nom.applicationMint(initiatedBy, quantity);
    }

    //******************************************************
    //OWNER ONLY RECOVERY FUNCTIONS FOR EMERGENCIES
    //******************************************************
    function lastDitchLock(uint16 tokenId) external onlyOwner {
        _hbContract.setInactiveOnThisChain(tokenId);
    }

    function lastDitchRelease(uint16 tokenId, address initiatedBy, bytes memory properties) external onlyOwner {
        _hbContract.setActiveOnThisChain(tokenId, properties, initiatedBy);
    }
}
