// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/external/avm/interfaces/iArbitrum_Inbox.sol



pragma solidity ^0.8.0;

// Retryable tickets are the Arbitrum protocol’s canonical method for passing generalized messages from Ethereum to
// Arbitrum. A retryable ticket is an L2 message encoded and delivered by L1; if gas is provided, it will be executed
// immediately. If no gas is provided or the execution reverts, it will be placed in the L2 retry buffer,
// where any user can re-execute for some fixed period (roughly one week).
// Retryable tickets are created by calling Inbox.createRetryableTicket.
// More details here: https://developer.offchainlabs.com/docs/l1_l2_messages#ethereum-to-arbitrum-retryable-tickets

interface iArbitrum_Inbox {
    function createRetryableTicketNoRefundAliasRewrite(
        address destAddr,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);
}


// File contracts/insured-bridge/avm/Arbitrum_CrossDomainEnabled.sol

// Copied logic from https://github.com/makerdao/arbitrum-dai-bridge/blob/34acc39bc6f3a2da0a837ea3c5dbc634ec61c7de/contracts/l1/L1CrossDomainEnabled.sol
// with a change to the solidity version.
pragma solidity ^0.8.0;

abstract contract Arbitrum_CrossDomainEnabled {
    iArbitrum_Inbox public immutable inbox;

    /**
     * @param _inbox Contract that sends generalized messages to the Arbitrum chain.
     */
    constructor(address _inbox) {
        inbox = iArbitrum_Inbox(_inbox);
    }

    // More details about retryable ticket parameters here: https://developer.offchainlabs.com/docs/l1_l2_messages#parameters
    // This function will not apply aliassing to the `user` address on L2.
    // Note: If `l1CallValue > 0`, then this contract must contain at least that much ETH to send as msg.value to the
    // inbox.
    function sendTxToL2NoAliassing(
        address target, // Address where transaction will initiate on L2.
        address user, // Address where excess gas is credited on L2.
        uint256 l1CallValue, // msg.value deposited to `user` on L2.
        uint256 maxSubmissionCost, // Amount of ETH allocated to pay for base submission fee. The user is charged this
        // fee to cover the storage costs of keeping their retryable ticket's calldata in the retry buffer. This should
        // also cover the `l2CallValue`, but we set that to 0. This amount is proportional to the size of `data`.
        uint256 maxGas, // Gas limit for immediate L2 execution attempt.
        uint256 gasPriceBid, // L2 gas price bid for immediate L2 execution attempt.
        bytes memory data // ABI encoded data to send to target.
    ) internal returns (uint256) {
        // createRetryableTicket API: https://developer.offchainlabs.com/docs/sol_contract_docs/md_docs/arb-bridge-eth/bridge/inbox#createretryableticketaddress-destaddr-uint256-l2callvalue-uint256-maxsubmissioncost-address-excessfeerefundaddress-address-callvaluerefundaddress-uint256-maxgas-uint256-gaspricebid-bytes-data-%E2%86%92-uint256-external
        // - address destAddr: destination L2 contract address
        // - uint256 l2CallValue: call value for retryable L2 message
        // - uint256 maxSubmissionCost: Max gas deducted from user's L2 balance to cover base submission fee
        // - address excessFeeRefundAddress: maxgas x gasprice - execution cost gets credited here on L2
        // - address callValueRefundAddress: l2CallValue gets credited here on L2 if retryable txn times out or gets cancelled
        // - uint256 maxGas: Max gas deducted from user's L2 balance to cover L2 execution
        // - uint256 gasPriceBid: price bid for L2 execution
        // - bytes data: ABI encoded data of L2 message
        uint256 seqNum =
            inbox.createRetryableTicketNoRefundAliasRewrite{ value: l1CallValue }(
                target,
                0, // we always assume that l2CallValue = 0
                maxSubmissionCost,
                user,
                user,
                maxGas,
                gasPriceBid,
                data
            );
        return seqNum;
    }
}


// File contracts/insured-bridge/interfaces/MessengerInterface.sol


pragma solidity ^0.8.0;

/**
 * @notice Sends cross chain messages to contracts on a specific L2 network. The `relayMessage` implementation will
 * differ for each L2.
 */
interface MessengerInterface {
    function relayMessage(
        address target,
        address userToRefund,
        uint256 l1CallValue,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 maxSubmissionCost,
        bytes memory message
    ) external payable;
}


// File @openzeppelin/contracts/utils/Context.sol@v4.1.0


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/Ownable.sol@v4.1.0


pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/insured-bridge/avm/Arbitrum_Messenger.sol


pragma solidity ^0.8.0;



/**
 * @notice Sends cross chain messages Arbitrum L2 network.
 * @dev This contract's owner should be set to the BridgeAdmin deployed on the same L1 network so that only the
 * BridgeAdmin can call cross-chain administrative functions on the L2 DepositBox via this messenger.
 * @dev This address will be the sender of any L1 --> L2 retryable tickets, so it should be set as the cross domain
 * owner for L2 contracts that expect to receive cross domain messages.
 */
contract Arbitrum_Messenger is Ownable, Arbitrum_CrossDomainEnabled, MessengerInterface {
    /**
     * @param _inbox Contract that sends generalized messages to the Arbitrum chain.
     */
    constructor(address _inbox) Arbitrum_CrossDomainEnabled(_inbox) {}

    /**
     * @notice Sends a message to an account on L2. If this message reverts on l2 for any reason it can either be
     * resent on L1, or redeemed on L2 manually. To learn more see how "retryable tickets" work on Arbitrum
     * https://developer.offchainlabs.com/docs/l1_l2_messages#parameters
     * @param target The intended recipient on L2.
     * @param userToRefund User on L2 to refund extra fees to.
     * @param l1CallValue Amount of ETH deposited to `target` contract on L2. Used to pay for L2 submission fee and
     * l2CallValue. This will usually be > 0.
     * @param gasLimit The gasLimit for the receipt of the message on L2.
     * @param gasPrice Gas price bid for L2 execution.
     * @param maxSubmissionCost: Max gas deducted from user's L2 balance to cover base submission fee.
     * This amount is proportional to the size of `data`.
     * @param message The data to send to the target (usually calldata to a function with
     *  `onlyFromCrossDomainAccount()`)
     */
    function relayMessage(
        address target,
        address userToRefund,
        uint256 l1CallValue,
        uint256 gasLimit,
        uint256 gasPrice,
        uint256 maxSubmissionCost,
        bytes memory message
    ) external payable override onlyOwner {
        // Since we know the L2 target's address in advance, we don't need to alias an L1 address.
        sendTxToL2NoAliassing(
            target,
            userToRefund,
            l1CallValue,
            maxSubmissionCost, // TODO: Determine the max submission cost. From the docs: "current base submission fee is queryable via ArbRetryableTx.getSubmissionPrice"
            gasLimit,
            gasPrice,
            message
        );
    }
}
