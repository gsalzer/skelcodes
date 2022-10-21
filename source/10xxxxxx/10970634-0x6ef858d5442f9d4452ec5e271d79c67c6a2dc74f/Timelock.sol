pragma solidity ^0.5.16;

import "./AegisMath.sol";

/**
 * @title Timelock
 * @author Aegis
 */
contract Timelock {
    using AegisMath for uint;

    uint public constant GRACE_PERIOD = 7 days;
    uint public constant MINIMUM_DELAY = 3 days;
    uint public constant MAXIMUM_DELAY = 14 days;
    address public admin;
    address public pendingAdmin;
    uint public delay;
    address payable public reserveAdmin;

    mapping (bytes32 => bool) public queuedTransactions;

    event NewDelay(uint indexed newDelay);
    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);


    constructor (address _admin, uint _delay, address payable _reserveAdmin) public {
        require(_delay >= MINIMUM_DELAY, "Must be greater than MINIMUM_DELAY");
        require(_delay <= MAXIMUM_DELAY, "Must be less than MAXIMUM_DELAY");

        admin = _admin;
        delay = _delay;
        reserveAdmin = _reserveAdmin;
    }

    function() external payable {}

    function setDelay(uint delay_) public {
        require(msg.sender == address(this), "Timelock::setDelay call must come from Timelock");
        require(delay_ >= MINIMUM_DELAY, "Timelock::setDelay delay must exceed minimum delay");
        require(delay_ <= MAXIMUM_DELAY, "Timelock::setDelay delay must not exceed maximum delay");
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin, "Timelock::acceptAdmin call must come from pendingAdmin");
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address _pendingAdmin) public {
        require(msg.sender == address(this), "Timelock::setPendingAdmin call must come from Timelock");
        pendingAdmin = _pendingAdmin;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "Timelock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(delay), "Timelock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "Timelock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "Timelock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(GRACE_PERIOD), "Timelock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        
        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);
        return returnData;
    }

    event ExecuteReduceReservesTransaction(address indexed target, uint value, string signature, bytes data);
    function executeReduceReservesTransaction(address target, uint value, bytes memory data) public payable returns (bytes memory) {
        string memory signature = "_reduceReserves(uint256,address)";
        require(msg.sender == reserveAdmin, "Timelock::executeReduceReservesTransaction: Call must come from admin.");
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        (bool success, bytes memory returnData) = target.call.value(value)(callData);
        require(success, "Timelock::executeReduceReservesTransaction: Transaction execution reverted.");

        emit ExecuteReduceReservesTransaction(target, value, signature, data);
        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        return block.timestamp;
    }
}
