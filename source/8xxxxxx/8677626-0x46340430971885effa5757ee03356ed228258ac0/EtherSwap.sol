pragma solidity ^0.5.8;

import "./Swap.sol";

// solium-disable security/no-call-value
contract EtherSwap is Swap {
    enum OrderState { HasFundingBalance, Claimed, Refunded }

    struct SwapOrder {
        address payable user;
        bytes32 paymentHash;
        bytes32 preimage;
        uint onchainAmount;
        uint refundBlockHeight;
        OrderState state;
        bool exist;
    }

    mapping(bytes16 => SwapOrder) orders;

    event OrderFundingReceived(bytes16 orderUUID, uint onchainAmount, bytes32 paymentHash, uint refundBlockHeight);
    event OrderClaimed(bytes16 orderUUID);
    event OrderRefunded(bytes16 orderUUID);

    /**
     * Allow the sender to fund a swap in one or more transactions.
     */
    function fund(bytes16 orderUUID, bytes32 paymentHash) external payable {
        SwapOrder storage order = orders[orderUUID];

        if (!order.exist) {
            order.user = msg.sender;
            order.exist = true;
            order.paymentHash = paymentHash;
            order.refundBlockHeight = block.number + refundDelay;
            order.state = OrderState.HasFundingBalance;
            order.onchainAmount = 0;
        } else {
            require(order.state == OrderState.HasFundingBalance, "Order already claimed or refunded.");
        }
        order.onchainAmount += msg.value;

        emit OrderFundingReceived(orderUUID, order.onchainAmount, order.paymentHash, order.refundBlockHeight);
    }

    /**
     * Allow the recipient to claim the funds once they know the preimage of the hashlock.
     * Anyone can claim but tokens only send to owner.
     */
    function claim(bytes16 orderUUID, bytes32 preimage) external {
        SwapOrder storage order = orders[orderUUID];

        require(order.exist == true, "Order does not exist.");
        require(order.state == OrderState.HasFundingBalance, "Order cannot be claimed.");
        require(sha256(abi.encodePacked(preimage)) == order.paymentHash, "Incorrect payment preimage.");
        require(block.number <= order.refundBlockHeight, "Too late to claim.");

        order.preimage = preimage;
        order.state = OrderState.Claimed;

        (bool success, ) = owner.call.value(order.onchainAmount)("");
        require(success, "Transfer failed.");

        emit OrderClaimed(orderUUID);
    }

    /**
     * Refund the sent amount back to the funder if the timelock has expired.
     */
    function refund(bytes16 orderUUID) external {
        SwapOrder storage order = orders[orderUUID];

        require(order.exist == true, "Order does not exist.");
        require(order.state == OrderState.HasFundingBalance, "Order cannot be refunded.");
        require(block.number > order.refundBlockHeight, "Too early to refund.");

        order.state = OrderState.Refunded;

        (bool success, ) = order.user.call.value(order.onchainAmount)("");
        require(success, "Transfer failed.");

        emit OrderRefunded(orderUUID);
    }
}

