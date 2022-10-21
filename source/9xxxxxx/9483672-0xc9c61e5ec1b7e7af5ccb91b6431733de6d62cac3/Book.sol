pragma solidity 0.5.15;

import "./AssetSwap.sol";

// Created by Eric George Falkenstein
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

contract Book {

    constructor(address user, address admin, uint16 minReqMarg, uint8 closefee,
        int16 frlong, int16 frshort)
        public {
            assetSwap = AssetSwap(admin);
            lp = user;
            lpMinTakeRM = minReqMarg;
            lastBookSettleTime = now;
            bookCloseFee = closefee;
            fundingRates[0] = frshort;
            fundingRates[1] = frlong;
            endOfBookTime = now + 1100 days;
        }

    address public lp;
    AssetSwap public assetSwap;
    /// 0 is actual or total margin, 1 is sum of LP's short takers
    /// 2 is sum of LP's long takers, 3 is the LP's required margin
    /// units an in wei, and refer to the RM, not the notional
    uint[4] public margin;
    uint public lastBookSettleTime;
    uint public burnFactor = 1 szabo;
    uint public settleNum;
    int public lpSettleDebitAcct;
    uint public endOfBookTime;
    int16[2] public fundingRates;
    uint16 public lpMinTakeRM;
    uint8 public bookStatus;
    uint8 public bookCloseFee;
    bytes32[][2] public tempContracts;
    bytes32[] public takerContracts;
    mapping(bytes32 => Subcontract) public subcontracts;

    struct Subcontract {
        address taker;
        uint takerMargin;   /// in wei
        uint requiredMargin;     /// in wei
        uint16 index;
        int16 fundingRate;
        uint8 closeFee;
        uint8 subkStatus;
        uint8 priceDay;
        int8 takerSide; /// 1 if long, -1 if short
    }

    modifier onlyAdmin() {
        require(msg.sender == address(assetSwap));
        _;
    }

    function adjustMinRMBook(uint16 _min)
        external
        onlyAdmin
    {
        lpMinTakeRM = _min;
    }

    function updateFeesBook(uint8 newClose, int16 longrate, int16 shortrate)
        external
        onlyAdmin
    {
        fundingRates[0] = shortrate;
        fundingRates[1] = longrate;
        bookCloseFee = newClose;
    }

    function burnTakerBook(bytes32 subkID, address sender, uint msgval)
        external
        onlyAdmin
        returns (uint)
    {
        Subcontract storage k = subcontracts[subkID];
        require(sender == k.taker, "must by party to his subcontract");
        require(settleNum == 0, "not during settlement process");
        require(k.subkStatus < 5, "can only burn active subcontract");
        uint burnFee = k.requiredMargin / 2;
        require(msgval >= burnFee, "Insufficient burn fee");
        burnFee = subzero(msgval, burnFee);
        if (margin[1] > margin[2]) {
            burnFactor = subzero(burnFactor, 1 szabo * k.requiredMargin / margin[1]);
        } else {
            burnFactor = subzero(burnFactor, 1 szabo * k.requiredMargin / margin[2]);
        }
        k.subkStatus = 5;
        return burnFee;
    }

    function burnLPBook(uint msgval)
        external
        onlyAdmin
        returns (uint)
    {
        require(bookStatus != 2, "can only burn once");
        /// burn fee is 50% of RM
        uint burnFee = margin[3] / 2;
        require(msgval >= burnFee, "Insufficient burn fee");
        burnFee = subzero(msgval, burnFee);
        /** The entire LP RM as a percent of the larger of the long or short
        * side is used to decrement the credits of those at the upcoming settlement
        */
        if (margin[2] > margin[1]) {
            burnFactor = subzero(burnFactor, 1 szabo * margin[3] / margin[2]);
        } else {
            burnFactor = subzero(burnFactor, 1 szabo * margin[3] / margin[1]);
        }
        bookStatus = 2;
        return burnFee;
    }

    function cancelBook(uint lastOracleSettle, bytes32 subkID, address sender, uint8 _endDay)
        external
        payable
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        require(lastOracleSettle < lastBookSettleTime, "Cannot do during settle period");
        require(sender == k.taker || sender == lp, "Canceller not LP or taker");
        /// checks to see if subk already cancelled, as otherwise redundant
        require(k.subkStatus == 1, "redundant or too new");
        uint feeOracle = 250 * k.requiredMargin / 1e4;
        /// users sends enough to cover the maximum cancel fee. Cancel fee less than the maximum is just sent to the taker's margin account
        require(msg.value >= (2 * feeOracle), "Insufficient cancel fee");
        uint feeLP = uint(k.closeFee) * k.requiredMargin / 1e4;
        if (endOfBookTime < (now + 28 days)) {
            feeLP = 0;
            feeOracle = 0;
        }
        if (sender == k.taker && _endDay == 5) {
            k.subkStatus = 2;  /// regular taker cancel
        } else if (sender == k.taker) {
            require(k.requiredMargin < subzero(margin[0], margin[3]), "Insuff LP RM for immed cancel");
            feeLP = feeOracle;  /// close fee is now max close fee, overriding initial close fee
            k.subkStatus = 4;  /// immediate taker cancel
            k.priceDay = _endDay;  /// this is the end-day of the subcontract's last week
        } else {
            feeOracle = 2 * feeOracle;
            feeLP = subzero(msg.value, feeOracle); /// this is really a refund to the LP, not a fee
            k.subkStatus = 3;  /// LP cancel
        }
        balanceSend(feeOracle, assetSwap.feeAddress());
        tempContracts[1].push(subkID);  /// sets this up to settle as an expiring subcontract
        margin[0] += feeLP;
        k.takerMargin += subzero(msg.value, feeLP + feeOracle);
    }

    function fundLPBook()
        external
        onlyAdmin
        payable
    {
        margin[0] += msg.value;
    }

    function fundTakerBook(bytes32 subkID)
        external
        onlyAdmin
        payable
    {
        Subcontract storage k = subcontracts[subkID];
        require(k.subkStatus < 2);
        k.takerMargin += msg.value;
    }

    function closeBookBook()
        external
        payable
        onlyAdmin
    { /// pays the close fee on the larger side of her book
        uint feeOracle = 250 * (margin[1] + margin[2] - min(margin[1], margin[2])) / 1e4;
        require(msg.value >= feeOracle, "Insufficient cancel fee");
        uint feeOverpay = msg.value - feeOracle;
        balanceSend(feeOracle, assetSwap.feeAddress());
        if (now > endOfBookTime)
        /// this means the next settlement ends this book's activity
            bookStatus = 1;
        else
        /// if initial, needs to be run again in 28 days to complete the shut down
            endOfBookTime = now + 28 days;
        margin[0] += feeOverpay;
    }

    /**
    *We only need look at when the last book settlement because
    * if the LP was at fault, someone could have inactivatedthe LP
    * and received a reward. Thus, the only scenario where a book
    * can be active and the LP not inactivated, is when the oracle has been
    * absent for a week
    */
    function inactiveOracleBook()
        external
        onlyAdmin
        {
        require(now > (lastBookSettleTime + 10 days));
        bookStatus = 3;
    }

    /** if the book was not settled, the LP is held accountable
     * the first counterparty to execute this function will then get a bonus credit of their RM from  *the LP
     * if the LP's total margin is zero, they will get whatever is there
     * after the book is in default all players can redeem their subcontracts
     * After a book is in default, this cannot be executed
     */
    function inactiveLPBook(bytes32 subkID, address sender, uint _lastOracleSettle)
        external
        onlyAdmin
    {

        require(bookStatus != 3);
        Subcontract storage k = subcontracts[subkID];
        require(k.taker == sender);
        require(_lastOracleSettle > lastBookSettleTime);
        require(subzero(now, _lastOracleSettle) > 48 hours);
        uint lpDefFee = min(margin[0], margin[3] / 2);
        margin[0] = subzero(margin[0], lpDefFee);
        margin[3] = 0;
        bookStatus = 3;
        /// annoying, but at least someone good get the negligent LP's money
        k.takerMargin += lpDefFee;
    }

    function redeemBook(bytes32 subkid, address sender)
        external
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkid];
        require(k.subkStatus > 5 || bookStatus == 3);
        /// redemption can happen if the subcontract has defaulted subkStatus = 6, is inactive subkStatus = 7
        /// or if the book is inactive (bookStatus == 3)
        uint tMargin = k.takerMargin;
        k.takerMargin = 0;
        uint16 index = k.index;
        /// iff the taker defaulted on an active book, they are penalized by
        /// burning RM/2 of their margin
        bool isDefaulted = (k.subkStatus == 6 && bookStatus == 0);
        uint defPay = k.requiredMargin / 2;
        uint lpPayment;
        address tAddress = k.taker;
        /// this pays the lp for the gas and effort of redeeming for the taker
        /// it's just 2 gwei. The investor should now see their margin in the
        /// assetSwapBalance, and withdraw from there
        if (sender == lp) {
            lpPayment = tMargin - subzero(tMargin, 2e9);
            tMargin -= lpPayment;
            margin[0] += lpPayment;
        }
        /** we have to pop the takerLong/Short lists to free up space
        * this involves this little trick, moving the last row to the row we are
        * redeeming and writing it over the redeemed subcontract
        * then we remove the duplicate.
        */
        Subcontract storage lastTaker = subcontracts[takerContracts[takerContracts.length - 1]];
        lastTaker.index = index;
        takerContracts[index] = takerContracts[takerContracts.length - 1];
        takerContracts.pop();
        delete subcontracts[subkid];
        // we only take what is there. It goes to the oracle, so if he's a cheater, you can punish
        /// him more by withholding this payment as well as the fraudulent PNL. If he's not a cheater
        /// then you are just negligent for defaulting and probably were not paying attention, as
        /// you should have know you couldn't cure your margin Friday afternoon before close.
        if (isDefaulted) {
            tMargin = subzero(tMargin, defPay);
            balanceSend(defPay, assetSwap.feeAddress());
        }
        /// money is sent to AssetSwapContract
        balanceSend(tMargin, tAddress);

    }

    /** Settle the rolled over taker sukcontracts
    * @param assetRet the returns for a long contract for a taker for only one
    * start day, as they are all starting on the prior settlement price
    */
    function settleRolling(int assetRet)
        external
        onlyAdmin
    {
        require(settleNum < 2e4, "done with rolling settle");
        int takerRetTemp;
        int lpTemp;
        /// the first settlement function set the settleNum = 1e4, so that is subtracted to
        /// see where we are in the total number of takers in the LP's book
        uint loopCap = min(settleNum - 1e4 + 250, takerContracts.length);
        for (uint i = (settleNum - 1e4); i < loopCap; i++) {
            Subcontract storage k = subcontracts[takerContracts[i]];
            if (k.subkStatus == 1) {
                takerRetTemp = int(k.takerSide) * assetRet * int(k.requiredMargin) / 1
                szabo - (int(k.fundingRate) * int(k.requiredMargin) / 1e4);
                lpTemp = lpTemp - takerRetTemp;
                if (takerRetTemp < 0) {
                    k.takerMargin = subzero(k.takerMargin, uint(-takerRetTemp));
                } else {
                    k.takerMargin += uint(takerRetTemp) * burnFactor / 1 szabo;
                }
                if (k.takerMargin < k.requiredMargin) {
                    k.subkStatus = 6;
                    if (k.takerSide == 1)
                        margin[2] = subzero(margin[2], k.requiredMargin);
                    else
                        margin[1] = subzero(margin[1], k.requiredMargin);
                }
            }
        }
        settleNum += 250;
        if ((settleNum - 1e4) >= takerContracts.length)
            settleNum = 2e4;
        lpSettleDebitAcct += lpTemp;
    }

    /// this is the fourth and the final of the settlement functions
    function settleFinal()
        external
        onlyAdmin
    {
        require(settleNum == 3e4, "not done with all the subcontracts");
        /// this take absolute value of (long - short) to update the LP's RM
        if (margin[2] > margin[1])
            margin[3] = margin[2] - margin[1];
        else
            margin[3] = margin[1] - margin[2];
        if (lpSettleDebitAcct < 0)
            margin[0] = subzero(margin[0], uint(-lpSettleDebitAcct));
        else
        /// if the lpSettleDebitAcct is positive, we add it, but first apply the burnFactor
        /// to remove the burner's pnl in a pro-rata way
            margin[0] = margin[0] + uint(lpSettleDebitAcct) * burnFactor / 1 szabo;
        if (bookStatus != 0) {
            bookStatus = 3;
            margin[3] = 0;
        } else if (margin[0] < margin[3]) {
            // default scenario for LP
            bookStatus = 3;
            uint defPay = min(margin[0], margin[3] / 2);
            margin[0] = subzero(margin[0], defPay);
            balanceSend(defPay, assetSwap.feeAddress());
            margin[3] = 0;
        }
        // resets for our next book settlement
        lpSettleDebitAcct = 0;
        lastBookSettleTime = now;
        settleNum = 0;
        delete tempContracts[1];
        delete tempContracts[0];
        burnFactor = 1 szabo;
    }

    /** Create a new Taker long subcontract of the given parameters
    * @param taker the address of the party on the other side of the contract
    * @param rM the Szabo amount in the required margin
    * isTakerLong is +1 if taker is long, 0 if taker is short
    * @return subkID the id of the newly created subcontract
    */
    function takeBook(address taker, uint rM, uint lastOracleSettle, uint8 _priceDay, uint isTakerLong)
        external
        payable
        onlyAdmin
        returns (bytes32 subkID)
    {
        require(bookStatus == 0, "book is no longer taking positions");
        require((now + 28 days) < endOfBookTime, "book closing soon");
        require(rM >= uint(lpMinTakeRM) * 1 szabo, "must be greater than book min");
        require(lastOracleSettle < lastBookSettleTime, "Cannot do during settle period");
        uint availableMargin = subzero(margin[0] / 2 + margin[2 - isTakerLong], margin[1 + isTakerLong]);
        require(rM <= availableMargin && (margin[0] - margin[3]) > rM);
        require(rM <= availableMargin);
        margin[1 + isTakerLong] += rM;
        Subcontract memory order;
        order.requiredMargin = rM;
        order.takerMargin = msg.value;
        order.taker = taker;
        order.takerSide = int8(2 * isTakerLong - 1);
        margin[3] += rM;
        subkID = keccak256(abi.encodePacked(now, takerContracts.length));
        order.index = uint16(takerContracts.length);
        order.priceDay = _priceDay;
        order.fundingRate = fundingRates[isTakerLong];
        order.closeFee = bookCloseFee;
        subcontracts[subkID] = order;
        takerContracts.push(subkID);
        tempContracts[0].push(subkID);
        return subkID;
    }

    /** Withdrawing margin
    * reverts if during the settle period, oracleSettleTime > book settle time
    * also must leave total margin greater than the required margin
    */
    function withdrawLPBook(uint amount, uint lastOracleSettle)
        external
        onlyAdmin
    {
        require(margin[0] >= amount, "Cannot withdraw more than the margin");
         // if book is dead LP can take everything left, if not dead, can only take up to RM
        if (bookStatus != 3) {
            require(subzero(margin[0], amount) >= margin[3], "Cannot w/d more than excess margin");
            require(lastOracleSettle < lastBookSettleTime, "Cannot w/d during settle period");
        }
        margin[0] = subzero(margin[0], amount);
        balanceSend(amount, lp);
    }

    function withdrawTakerBook(bytes32 subkID, uint amount, uint lastOracleSettle, address sender)
        external
        onlyAdmin
    {
        require(lastOracleSettle < lastBookSettleTime, "Cannot w/d during settle period");
        Subcontract storage k = subcontracts[subkID];
        require(k.subkStatus < 6, "subk dead, must redeem");
        require(sender == k.taker, "Must be taker to call this function");
        require(subzero(k.takerMargin, amount) >= k.requiredMargin, "cannot w/d more than excess margin");
        k.takerMargin = subzero(k.takerMargin, amount);
        balanceSend(amount, k.taker);
    }

    function getSubkData1Book(bytes32 subkID)
        external
        view
        returns (address takerAddress, uint takerMargin, uint requiredMargin)
    {   Subcontract memory k = subcontracts[subkID];
        takerAddress = k.taker;
        takerMargin = k.takerMargin;
        requiredMargin = k.requiredMargin;
    }

    function getSubkData2Book(bytes32 subkID)
        external
        view
        returns (uint8 kStatus, uint8 priceDay, uint8 closeFee, int16 fundingRate, bool takerSide)
    {   Subcontract memory k = subcontracts[subkID];
        kStatus = k.subkStatus;
        priceDay = k.priceDay;
        closeFee = k.closeFee;
        fundingRate = k.fundingRate;
        if (k.takerSide == 1)
            takerSide = true;
    }

    function getSettleInfoBook()
        external
        view
        returns (uint totalLength, uint expiringLength, uint newLength, uint lastBookSettleUTC, uint settleNumber,
            uint bookBalance, uint bookMaturityUTC)
    {
        totalLength = takerContracts.length;
        expiringLength = tempContracts[1].length;
        newLength = tempContracts[0].length;
        lastBookSettleUTC = lastBookSettleTime;
        settleNumber = settleNum;
        bookMaturityUTC = endOfBookTime;
        bookBalance = address(this).balance;
    }

    /** Settle the taker long sukcontracts
    * priceDay Expiring returns use the return from the last settle to the priceDay, which
    * for regular cancels is just 5, the most recent settlement price
    * this is the first of 4 settlement functions
    * */
    function settleExpiring(int[5] memory assetRetExp)
        public
        onlyAdmin
        {
        require(bookStatus != 3 && settleNum < 1e4, "done with expiry settle");
        int takerRetTemp;
        int lpTemp;
        uint loopCap = min(settleNum + 200, tempContracts[1].length);
        for (uint i = settleNum; i < loopCap; i++) {
            Subcontract storage k = subcontracts[tempContracts[1][i]];
            takerRetTemp = int(k.takerSide) * assetRetExp[k.priceDay - 1] * int(k.requiredMargin) / 1 szabo -
            (int(k.fundingRate) * int(k.requiredMargin) / 1e4);
            lpTemp -= takerRetTemp;
            if (takerRetTemp < 0) {
                k.takerMargin = subzero(k.takerMargin, uint(-takerRetTemp));
            } else {
                k.takerMargin += uint(takerRetTemp) * burnFactor / 1 szabo;
            }
            if (k.takerSide == 1)
                margin[2] = subzero(margin[2], k.requiredMargin);
            else
                margin[1] = subzero(margin[1], k.requiredMargin);
            k.subkStatus = 7;
        }
        settleNum += 200;
        if (settleNum >= tempContracts[1].length)
            settleNum = 1e4;
        lpSettleDebitAcct += lpTemp;
    }

    /// this is the third of the settlement functions
    function settleNew(int[5] memory assetRets)
        public
        onlyAdmin
    {
        require(settleNum < 3e4, "done with new settle");
        int takerRetTemp;
        int lpTemp;
        /// after running the second settlement function, settleRolling, it is set to 2e4
        uint loopCap = min(settleNum - 2e4 + 200, tempContracts[0].length);
        for (uint i = (settleNum - 2e4); i < loopCap; i++) {
            Subcontract storage k = subcontracts[tempContracts[0][i]];
            /// subkStatus set to 'active' which means it can be cancelled
            /// it will also be settled in the settleRolling if not cancelled
            /// using the more efficient settlement that uses just one return, from last to most recent settlement
            k.subkStatus = 1;
            if (k.priceDay != 5) {
                takerRetTemp = int(k.takerSide) * assetRets[k.priceDay] * int(k.requiredMargin) / 1
                szabo - (int(k.fundingRate) * int(k.requiredMargin) / 1e4);
                lpTemp = lpTemp - takerRetTemp;
                if (takerRetTemp < 0) {
                    k.takerMargin = subzero(k.takerMargin, uint(-takerRetTemp));
                } else {
                    k.takerMargin += uint(takerRetTemp) * burnFactor / 1 szabo;
                }
                if (k.takerMargin < k.requiredMargin) {
                    k.subkStatus = 6;
                    if (k.takerSide == 1)
                        margin[2] = subzero(margin[2], k.requiredMargin);
                    else
                        margin[1] = subzero(margin[1], k.requiredMargin);
                }
                k.priceDay = 5;
            }
        }
        settleNum += 200;
        if (settleNum >= tempContracts[0].length)
            settleNum = 3e4;
        lpSettleDebitAcct += lpTemp;
    }

    /// Function to send balances back to the Assetswap contract
    function balanceSend(uint amount, address recipient)
        internal
    {
        assetSwap.balanceInput.value(amount)(recipient);
    }

    /** Utility function to find the minimum of two unsigned values
    * @notice returns the first parameter if they are equal
    */
    function min(uint a, uint b)
        internal
        pure
        returns (uint)
    {
        if (a <= b)
            return a;
        else
            return b;
    }

    function subzero(uint _a, uint _b)
        internal
        pure
        returns (uint)
    {
        if (_b >= _a)
            return 0;
        else
            return _a - _b;
    }


}

