//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
// pragma experimental SMTChecker;
import "./MTokenWrap.sol";

contract MTokenDeSwap is MTokenWrap {
    using SafeMath for uint256;

    //PENDING=》CANCELED
    //PENDING=》APPROVED
    //APPROVED=》FINISHED
    enum OrderStatus {PENDING, CANCELED, APPROVED, FINISHED}

    function getStatusString(OrderStatus status)
        internal
        pure
        returns (string memory)
    {
        if (status == OrderStatus.PENDING) {
            return "pending";
        } else if (status == OrderStatus.CANCELED) {
            return "canceled";
        } else if (status == OrderStatus.APPROVED) {
            return "approved";
        } else if (status == OrderStatus.FINISHED) {
            return "finished";
        } else {
            // unreachable.
            return "unknown";
        }
    }

    struct UnWrapOrder {
        address ethAccount;
        uint256 nativeCoinAmount;
        uint256 mtokenAmount;
        string nativeCoinAddress;
        string nativeTxId;
        uint256 requestBlockNo;
        uint256 confirmedBlockNo;
        OrderStatus status;
        uint256 fee;
        uint256 rate;
    }

    UnWrapOrder[] public unWrapOrders;
    bool public paused = false;
    modifier notPaused() {
        require(!paused, "paused");
        _;
    }

    function pause(bool _paused) public onlyOwner returns (bool) {
        paused = _paused;
        return true;
    }

    function getUnWrapOrderNum() public view returns (uint256) {
        return unWrapOrders.length;
    }

    function getUnWrapOrderInfo(uint256 seq)
        public
        view
        returns (
            address ethAccount,
            uint256 nativeCoinAmount,
            uint256 mtokenAmount,
            string memory nativeCoinAddress,
            string memory nativeTxId,
            uint256 requestBlockNo,
            uint256 confirmedBlockNo,
            string memory status
        )
    {
        require(seq < unWrapOrders.length, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        ethAccount = order.ethAccount;
        nativeCoinAmount = order.nativeCoinAmount;
        mtokenAmount = order.mtokenAmount;
        nativeCoinAddress = order.nativeCoinAddress;
        nativeTxId = order.nativeTxId;
        requestBlockNo = order.requestBlockNo;
        confirmedBlockNo = order.confirmedBlockNo;
        status = getStatusString(order.status);
    }

    function calcUnWrapAmount(
        uint256 amt,
        uint256 fee,
        uint256 rate
    ) public pure returns (uint256) {
        return amt.sub(fee).mul(rate).div(rate_precision);
    }

    function unWrap(
        uint256 amt,
        uint256 fee,
        uint256 rate,
        string memory nativeCoinAddress
    ) public notPaused returns (bool) {
        address ethAccount = msg.sender;
        uint256 mtokenAmount = amt;
        uint256 nativeCoinAmount = calcUnWrapAmount(amt, fee, rate);
        require(
            mtoken.transferFrom(ethAccount, mtokenRepository, mtokenAmount),
            "transferFrom failed"
        );
        uint256 seq = unWrapOrders.length;
        unWrapOrders.push(
            UnWrapOrder({
                ethAccount: ethAccount,
                nativeCoinAmount: nativeCoinAmount,
                mtokenAmount: mtokenAmount,
                nativeCoinAddress: nativeCoinAddress,
                requestBlockNo: block.number,
                status: OrderStatus.PENDING,
                nativeTxId: "",
                confirmedBlockNo: 0,
                fee: fee,
                rate: rate
            })
        );
        emit UNWRAP_REQUEST(seq, ethAccount, nativeCoinAddress, amt, fee, rate);

        return true;
    }

    event UNWRAP_REQUEST(
        uint256 indexed seq,
        address ethAccount,
        string nativeCoinAddress,
        uint256 amt,
        uint256 fee,
        uint256 rate
    );

    event UNWRAP_APPROVE(uint256 indexed seq);

    function approveUnWrapOrder(
        uint256 seq,
        address ethAccount,
        uint256 nativeCoinAmount,
        uint256 mtokenAmount,
        string memory nativeCoinAddress
    ) public onlyOwner returns (bool) {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(order.status == OrderStatus.PENDING, "status not pending");
        require(ethAccount == order.ethAccount, "invalid param1");
        require(mtokenAmount == order.mtokenAmount, "invalid param2");
        require(nativeCoinAmount == order.nativeCoinAmount, "invalid param3");
        require(
            stringEquals(nativeCoinAddress, order.nativeCoinAddress),
            "invalid param4"
        );

        unWrapOrders[seq].status = OrderStatus.APPROVED;
        emit UNWRAP_APPROVE(seq);
        return true;
    }

    event UNWRAP_CANCEL(uint256 indexed seq);

    function cancelUnWrapOrder(uint256 seq) public returns (bool) {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(msg.sender == order.ethAccount, "invalid auth.");
        require(order.status == OrderStatus.PENDING, "status not pending");
        unWrapOrders[seq].status = OrderStatus.CANCELED;

        require(
            mtoken.transferFrom(
                mtokenRepository,
                order.ethAccount,
                order.mtokenAmount
            ),
            "transferFrom failed"
        );

        emit UNWRAP_CANCEL(seq);
        return true;
    }

    function stringEquals(string memory s1, string memory s2)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked(s1)) ==
            keccak256(abi.encodePacked(s2)));
    }

    event UNWRAP_FINISH(uint256 indexed seq, string nativeTxId);

    function finishUnWrapOrder(uint256 seq, string memory nativeTxId)
        public
        onlyOwner
        returns (bool)
    {
        require(unWrapOrders.length > seq, "invalid seq");
        UnWrapOrder memory order = unWrapOrders[seq];
        require(order.status == OrderStatus.APPROVED, "status not approved");

        unWrapOrders[seq].status = OrderStatus.FINISHED;
        unWrapOrders[seq].nativeTxId = nativeTxId;
        unWrapOrders[seq].confirmedBlockNo = block.number;
        emit UNWRAP_FINISH(seq, nativeTxId);
        return true;
    }
}

