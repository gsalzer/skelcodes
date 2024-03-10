// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import { Lib_NVMCodec } from "../../../libraries/codec/Lib_NVMCodec.sol";
import { Lib_Receipt } from "../../../libraries/codec/Lib_Receipt.sol";
import { Lib_AddressResolver } from "../../../libraries/resolver/Lib_AddressResolver.sol";
import { Lib_NVMCodec } from "../../../libraries/codec/Lib_NVMCodec.sol";
import { Lib_AddressManager } from "../../../libraries/resolver/Lib_AddressManager.sol";
import { Lib_SecureMerkleTrie } from "../../../libraries/trie/Lib_SecureMerkleTrie.sol";
import { Lib_PredeployAddresses } from "../../../libraries/constants/Lib_PredeployAddresses.sol";
import { Lib_CrossDomainUtils } from "../../../libraries/bridge/Lib_CrossDomainUtils.sol";
import { Lib_EIP155Tx } from "../../../libraries/codec/Lib_EIP155Tx.sol";

/* Interface Imports */
import { iNVM_L1CrossDomainMessenger } from
    "../../../iNVM/bridge/messaging/iNVM_L1CrossDomainMessenger.sol";
import { iNVM_StateCommitmentChain } from "../../../iNVM/chain/iNVM_StateCommitmentChain.sol";
import { iNVM_ExecutionManager } from "../../../iNVM/execution/iNVM_ExecutionManager.sol";
import { iNVM_MessageQueue } from "../../../iNVM/chain/iNVM_MessageQueue.sol";
import { iNVM_FraudVerifier } from "../../../iNVM/verification/iNVM_FraudVerifier.sol";

/* External Imports */
import { OwnableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title NVM_L1CrossDomainMessenger
 * @dev The L1 Cross Domain Messenger contract sends messages from L1 to L2, and relays messages
 * from L2 onto L1. In the event that a message sent from L1 to L2 is rejected for exceeding the L2
 * epoch gas limit, it can be resubmitted via this contract's replay function.
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract NVM_L1CrossDomainMessenger is
        iNVM_L1CrossDomainMessenger,
        Lib_AddressResolver,
        OwnableUpgradeable,
        PausableUpgradeable,
        ReentrancyGuardUpgradeable
{

    /**********
     * Events *
     **********/

    event MessageBlocked(
        bytes32 indexed _xDomainCalldataHash
    );

    event MessageAllowed(
        bytes32 indexed _xDomainCalldataHash
    );

    /*************
     * Constants *
     *************/

    // The default x-domain message sender being set to a non-zero value makes
    // deployment a bit more expensive, but in exchange the refund on every call to
    // `relayMessage` by the L1 and L2 messengers will be higher.
    address internal constant DEFAULT_XDOMAIN_SENDER = 0x000000000000000000000000000000000000dEaD;

    /**********************
     * Contract Variables *
     **********************/

    mapping (bytes32 => bool) public blockedMessages;
    mapping (bytes32 => bool) public relayedMessages;
    mapping (bytes32 => bool) public successfulMessages;

    address internal xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

    /***************
     * Constructor *
     ***************/

    /**
     * This contract is intended to be behind a delegate proxy.
     * We pass the zero address to the address resolver just to satisfy the constructor.
     * We still need to set this value in initialize().
     */
    constructor()
        Lib_AddressResolver(address(0))
    {}

    /**********************
     * Function Modifiers *
     **********************/

    /**
     * Modifier to enforce that, if configured, only the NVM_L2MessageRelayer contract may
     * successfully call a method.
     */
    modifier onlyRelayer() {
        address relayer = resolve("NVM_L2MessageRelayer");
        if (relayer != address(0)) {
            require(
                msg.sender == relayer,
                "Only NVM_L2MessageRelayer can relay L2-to-L1 messages."
            );
        }
        _;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * @param _libAddressManager Address of the Address Manager.
     */
    function initialize(
        address _libAddressManager
    )
        public
        initializer
    {
        require(
            address(libAddressManager) == address(0),
            "L1CrossDomainMessenger already intialized."
        );
        libAddressManager = Lib_AddressManager(_libAddressManager);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        // Initialize upgradable OZ contracts
        __Context_init_unchained(); // Context is a dependency for both Ownable and Pausable
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    /**
     * Pause relaying.
     */
    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    /**
     * Block a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function blockMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = true;
        emit MessageBlocked(_xDomainCalldataHash);
    }

    /**
     * Allow a message.
     * @param _xDomainCalldataHash Hash of the message to block.
     */
    function allowMessage(
        bytes32 _xDomainCalldataHash
    )
        external
        onlyOwner
    {
        blockedMessages[_xDomainCalldataHash] = false;
        emit MessageAllowed(_xDomainCalldataHash);
    }

    function xDomainMessageSender()
        public
        override
        view
        returns (
            address
        )
    {
        require(xDomainMsgSender != DEFAULT_XDOMAIN_SENDER, "xDomainMessageSender is not set");
        return xDomainMsgSender;
    }

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes memory _message,
        uint32 _gasLimit
    )
        override
        public
    {
        address nvmMessageQueue = resolve("NVM_MessageQueue");

        uint40 nonce =
            iNVM_MessageQueue(nvmMessageQueue).getQueueLength();

        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            msg.sender,
            _message,
            nonce
        );

        address l2CrossDomainMessenger = resolve("NVM_L2CrossDomainMessenger");
        _sendXDomainMessage(
            l2CrossDomainMessenger,
            xDomainCalldata,
            _gasLimit
        );
        emit SentMessage(xDomainCalldata);
    }

    /**
     * Relays a cross domain message to a contract.
     * @inheritdoc iNVM_L1CrossDomainMessenger
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        //tx
        Lib_NVMCodec.Transaction memory _nvmTransaction,
        //receipt
        Lib_NVMCodec.Receipt memory _receipt,
        L2MessageInclusionProof memory _proof
    )
        override
        public
        nonReentrant
        onlyRelayer
        whenNotPaused
    {
        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _messageNonce
        );

        require(
            _verifyXDomainMessage(
                xDomainCalldata,
                _proof,
                _nvmTransaction,
                _receipt
            ) == true,
            "Provided message could not be verified."
        );

        bytes32 xDomainCalldataHash = keccak256(xDomainCalldata);

        require(
            successfulMessages[xDomainCalldataHash] == false,
            "Provided message has already been received."
        );

        require(
            blockedMessages[xDomainCalldataHash] == false,
            "Provided message has been blocked."
        );

        require(
            _target != resolve("NVM_MessageQueue"),
            "Cannot send L2->L1 messages to L1 system contracts."
        );

        xDomainMsgSender = _sender;
        (bool success, ) = _target.call(_message);
        xDomainMsgSender = DEFAULT_XDOMAIN_SENDER;

        // Mark the message as received if the call was successful. Ensures that a message can be
        // relayed multiple times in the case that the call reverted.
        if (success == true) {
            successfulMessages[xDomainCalldataHash] = true;
            emit RelayedMessage(xDomainCalldataHash);
        } else {
            emit FailedRelayedMessage(xDomainCalldataHash);
        }

        // Store an identifier that can be used to prove that the given message was relayed by some
        // user. Gives us an easy way to pay relayers for their work.
        bytes32 relayId = keccak256(
            abi.encodePacked(
                xDomainCalldata,
                msg.sender,
                block.number
            )
        );
        relayedMessages[relayId] = true;
    }

    /**
     * Replays a cross domain message to the target messenger.
     * @inheritdoc iNVM_L1CrossDomainMessenger
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _gasLimit
    )
        override
        public
    {
        // Verify that the message is in the queue:
        address messageQueue = resolve("NVM_MessageQueue");
        Lib_NVMCodec.QueueElement memory element =
            iNVM_MessageQueue(messageQueue).getQueueElement(_queueIndex);

        address l2CrossDomainMessenger = resolve("NVM_L2CrossDomainMessenger");
        // Compute the transactionHash
        bytes32 transactionHash = keccak256(
            abi.encode(
                address(this),
                l2CrossDomainMessenger,
                _gasLimit,
                _message
            )
        );

        require(
            transactionHash == element.transactionHash,
            "Provided message has not been enqueued."
        );

        bytes memory xDomainCalldata = Lib_CrossDomainUtils.encodeXDomainCalldata(
            _target,
            _sender,
            _message,
            _queueIndex
        );

        _sendXDomainMessage(
            l2CrossDomainMessenger,
            xDomainCalldata,
            _gasLimit
        );
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Verifies that the given message is valid.
     * @param _xDomainCalldata Calldata to verify.
     * @param _proof Inclusion proof for the message.
     * @return Whether or not the provided message is valid.
     */
    function _verifyXDomainMessage(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof,
        Lib_NVMCodec.Transaction memory _nvmTransaction,
        Lib_NVMCodec.Receipt memory _receipt
    )
        internal
        view
        returns (
            bool
        )
    {
        return (
            _verifyStateRootProof(_nvmTransaction, _receipt, _proof)
            && _verifyStorageProof(_xDomainCalldata, _proof)
        );
    }

    /**
     * Verifies that the state root within an inclusion proof is valid.
     * @param _nvmTransaction Message transaction.
     * @param _receipt Message receipt.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStateRootProof(
        Lib_NVMCodec.Transaction memory _nvmTransaction,
        Lib_NVMCodec.Receipt memory _receipt,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        iNVM_FraudVerifier nvmFraudVerifier = iNVM_FraudVerifier(
            resolve("NVM_FraudVerifier")
        );

        return (
            _proof.stateRoot == _receipt.stateRoot &&
            Lib_NVMCodec.hashTransaction(_nvmTransaction) == _receipt.nvmTransactionHash &&
            Lib_Receipt.verifyOperatorSignature(_receipt, resolve("NVM_Sequencer")) &&
            nvmFraudVerifier.insideFraudProofWindow(_nvmTransaction) == false
        );
    }

    /**
     * Verifies that the storage proof within an inclusion proof is valid.
     * @param _xDomainCalldata Encoded message calldata.
     * @param _proof Message inclusion proof.
     * @return Whether or not the provided proof is valid.
     */
    function _verifyStorageProof(
        bytes memory _xDomainCalldata,
        L2MessageInclusionProof memory _proof
    )
        internal
        view
        returns (
            bool
        )
    {
        bytes32 storageKey = keccak256(
            abi.encodePacked(
                keccak256(
                    abi.encodePacked(
                        _xDomainCalldata,
                        resolve("NVM_L2CrossDomainMessenger")
                    )
                ),
                uint256(0)
            )
        );

        (
            bool exists,
            bytes memory encodedMessagePassingAccount
        ) = Lib_SecureMerkleTrie.get(
            abi.encodePacked(Lib_PredeployAddresses.L2_TO_L1_MESSAGE_PASSER),
            _proof.stateTrieWitness,
            _proof.stateRoot
        );

        require(
            exists == true,
            "Message passing predeploy has not been initialized or invalid proof provided."
        );

        Lib_NVMCodec.EVMAccount memory account = Lib_NVMCodec.decodeEVMAccount(
            encodedMessagePassingAccount
        );

        return Lib_SecureMerkleTrie.verifyInclusionProof(
            abi.encodePacked(storageKey),
            abi.encodePacked(uint8(1)),
            _proof.storageTrieWitness,
            account.storageRoot
        );
    }

    /**
     * Sends a cross domain message.
     * @param _l2CrossDomainMessenger Address of the NVM_L2CrossDomainMessenger instance.
     * @param _message Message to send.
     * @param _gasLimit OVM gas limit for the message.
     */
    function _sendXDomainMessage(
        address _l2CrossDomainMessenger,
        bytes memory _message,
        uint256 _gasLimit
    )
        internal
    {
        iNVM_MessageQueue(resolve("NVM_MessageQueue")).enqueue(
            resolve("NVM_L2CrossDomainMessenger"),
            _gasLimit,
            _message
        );
    }
}

