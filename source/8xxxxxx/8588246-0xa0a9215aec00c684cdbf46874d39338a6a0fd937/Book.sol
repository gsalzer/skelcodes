
pragma solidity ^0.5.11;

import "./AssetSwap.sol";
contract Book {

    /** Sets up a new Book for an LP.
    * @notice each LP should have only one book
    * @dev the minumum take size is established here and never changes
    * @param user the address of the LP the new book should belong to
    * @param admin gives the AssetSwap contract the right to read and write to this contract
    * @param minBalance the minimum balance size in finney
    */
     constructor(address user, address  admin, uint minBalance)
        public
    {
        assetSwap = AssetSwap(admin);
        lp = user;
        minRM = minBalance * 1 finney;
        lastBookSettleTime = now;
    }

    address public lp;
    AssetSwap public assetSwap;
    bool public bookDefaulted;
    uint public settleNum;
    uint public LPMargin;
    uint public LPLongMargin;    // total RM of all subks where lp is long
    uint public LPShortMargin;   // total RM of all subks where lp is short
    uint public LPRequiredMargin;   // ajusted by take, reset at settle
    uint public lastBookSettleTime;
    uint public minRM;
    uint public debitAcct;
    uint internal constant BURN_DEF_FEE = 2; // burn and default fee, applied as RM/BURN_DEF_FEE
    //  after 9 days without an Oracle settlement, all players can redeem their contracts
    //  after one player executes the invactiveOracle function, which uses this constant, the book is in default allowing
    // anyone to redeem their subcontracts and withdraw their margin
    uint internal constant ORACLE_MAX_ABSENCE = 0 days;
    // as long and short settlements are executed separately, prevents the oracle
    // from settling either side twice on settlement day
    uint internal constant NO_DOUBLE_SETTLES = 0 days;
    // settlement uses gas, and so this max prevents the accumulation of so many subcontracts the Book could never settle
    // uint internal constant MAX_SUBCONTRACTS = 225;
    uint internal constant CLOSE_FEE = 200;
    uint internal constant LP_MAX_SETTLE = 0 days;
    bytes32[] public shortTakerContracts; // note this implies the lp is long
    bytes32[] public longTakerContracts;  // and here the  lp is short
    mapping(bytes32 => Subcontract) public subcontracts;
    address payable internal constant BURN_ADDRESS = address(0xdead);  // address payable

    struct Subcontract {
        uint index;
		address taker;
		uint takerMargin;   // in wei
		uint reqMargin;     // in wei
        uint8 startDay;     // 0 for initial price on settlement, 1 for day after, etc, though 7 implies settlement day
        bool takerCloseDisc;
		bool LPSide;        // true for LP long, taker Short
		bool isCancelled;
		bool takerBurned;
		bool LPBurned;
		bool takerDefaulted;
        bool isActive;
	}


    modifier onlyAdmin()
    {
        require(msg.sender == address(assetSwap));
        _;
    }

    /** Allow the LP to change the minimum take size in their book
    * @param _min the minimum take size in ETH for the book
    */
    function adjustMinRM(uint _min)
        public
        onlyAdmin
    {
        minRM = _min * 1 finney;
    }

    /** Allow the OracleSwap admin to cancel any  subcontract
    * @param subkID the subcontract to cancel
    */
    function adminCancel(bytes32 subkID)
        public
        payable
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        k.isCancelled = true;
    }

    /** Allow the OracleSwap admin to cancel any  subcontract
    */
    function adminStop()
        public
        payable
        onlyAdmin
    {
        bookDefaulted = true;
        LPRequiredMargin = 0;
    }

    /** Function to send balances back to the Assetswap contract
    * @param amount the amount in wei to send
    * @param recipient the address to credit the balance to
    */
    function balanceSend(uint amount, address recipient)
        internal
    {
        assetSwap.balanceTransfer.value(amount)(recipient);
    }

    /** Burn a subcontract
    * @param subkID the subcontract id
    * @param sender who called the function in AssetSwap
    * @param amount the message value
    */
    function bookBurn( bytes32 subkID, address sender, uint amount)
        public
        payable
        onlyAdmin
        returns (uint)
    {
        Subcontract storage k = subcontracts[subkID];
        require(sender == lp || sender == k.taker, "must by party to his subcontract");
        // cost to burn
		uint burnFee = k.reqMargin / BURN_DEF_FEE;
		require (amount >= burnFee);
		if (sender == lp)
		    k.LPBurned = true;
		else
		    k.takerBurned = true;
		return burnFee;
    }

     /** Cancel a subcontract
    * @param lastOracleSettleTime the last settle price timestamp
    * @param subkID the subcontract id
    */
    function bookCancel(uint lastOracleSettleTime, bytes32 subkID, address sender)
        public
        payable
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
 //       require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
		require(sender == k.taker || sender == lp, "Canceller not LP or taker");
        require(!k.isCancelled, "Subcontract already cancelled");
        uint fee;
        fee =(k.reqMargin * CLOSE_FEE)/1e4 ;
        if (k.takerCloseDisc || (sender == lp))
           fee = 3 * fee / 2;
		require(msg.value >= fee, "Insufficient cancel fee");
        k.isCancelled = true;
        balanceSend(msg.value - fee, sender);
        balanceSend(fee, assetSwap.feeAddress());
    }

    /** Deposit ETH into the LP margin
    * @notice the message value is directly deposited
    */
    function fundLPMargin()
        public
        payable
    {
        LPMargin = add(LPMargin,msg.value);
    }

    /** Deposit ETH into a taker's margin
    * @param subkID the id of the subcontract to deposit into
    * @notice the message value is directly deposited.
    */
    function fundTakerMargin(bytes32 subkID)
        public
        payable
    {
        Subcontract storage k = subcontracts[subkID];
        require (k.reqMargin > 0);
        k.takerMargin= add(k.takerMargin,msg.value);
    }

    /** This function returns the stored values of a subcontract
    * @param subkID the subcontract id
    * @return takerMargin the takers actual margin balance
    * @return reqMargin the required margin for both parties for the subcontract
    * @return startDay the integer value corresponding to the index (day) for retrieving prices
    * @return LPSide, the side of the contract in terms of the LP, eg, true implies lp is long, taker is short
    * @return takerCloseFee, as these depend on the size of the LP book when taken relative to the AssetSwap's Global_size_discout
    * that distinguishes between large and small lps for this assetswap, where larger LP books have half the closing fee that
    * small LP books have
    *
    */
        function getSubkData(bytes32 subkID)
        public
        view
        returns (uint _takerMargin, uint _reqMargin,
          bool _lpside, bool isCancelled, bool isActive, uint8 _startDay)
    {
        Subcontract storage k = subcontracts[subkID];
        _takerMargin = k.takerMargin;
        _reqMargin = k.reqMargin;
        _lpside = k.LPSide;
        isCancelled = k.isCancelled;
        isActive = k.isActive;
        _startDay = k.startDay;
    }


    /** This function returns the stored values of a subcontract
    *
    */

      function getSubkDetail(bytes32 subkID)
        public
        view
        returns (bool closeDisc, bool takerBurned, bool LPBurned, bool takerDefaulted)
    {
        Subcontract storage k = subcontracts[subkID];
        closeDisc = k.takerCloseDisc;
        takerBurned = k.takerBurned;
        LPBurned = k.LPBurned;
        takerDefaulted = k.takerDefaulted;
    }


    /** if the Oracle neglects the OracleContract, any player can set the book into default by executing this function
     * then all players can redeem their subcontracts
     *
     */

     function inactiveOracle()
        public
        {
          require(now > (lastBookSettleTime + ORACLE_MAX_ABSENCE));

          bookDefaulted = true;
          LPRequiredMargin = 0;
        }

    /** if the book was not settled, the LP is held accountable
     * the first counterparty to execute this function will then get a bonus credit of their RM from the LP
     * if the LP's total margin is zero, they will get whatever is there
     * after the book is in default all players can redeem their subcontracts
     * After a book is in default, this cannot be executed
     */

    function inactiveLP(uint _lastOracleSettleTime, bytes32 subkID)
        public
    {
          require(_lastOracleSettleTime > lastBookSettleTime);
          require( now > (_lastOracleSettleTime + LP_MAX_SETTLE));
          require(!bookDefaulted);
          Subcontract storage k = subcontracts[subkID];
          uint LPfee = min(LPMargin,k.reqMargin);
          uint defPay = subzero(LPRequiredMargin/2,LPfee);
          LPMargin = subzero(LPMargin,add(LPfee,defPay));
          k.takerMargin = add(k.takerMargin,LPfee);
          bookDefaulted = true;
          LPRequiredMargin = 0;
    }
    /** Refund the balances and remove from storage a subcontract that has been defaulted, cancelled,
    * burned, or expired.
    * @param subkID the id of the subcontract
    * this is done separately from settlement because it requires a modest amount of gas
    * and would otherwise severely reduce the number of potential long and short contracts
    */
    function redeemSubcontract(bytes32 subkID)
        public
        onlyAdmin
    {
        Subcontract storage k = subcontracts[subkID];
        require(!k.isActive || bookDefaulted);
        uint tMargin = k.takerMargin;
        if (k.takerDefaulted) {
            uint defPay = k.reqMargin / BURN_DEF_FEE;
            tMargin = subzero(tMargin,defPay);
        BURN_ADDRESS.transfer(defPay);
        }
        k.takerMargin = 0;
        balanceSend(tMargin, k.taker);
        uint index = k.index;
        if (k.LPSide) {
            Subcontract storage lastShort = subcontracts[shortTakerContracts[shortTakerContracts.length - 1]];
            lastShort.index = index;
            shortTakerContracts[index] = shortTakerContracts[shortTakerContracts.length - 1];
            shortTakerContracts.pop();
        } else {
            Subcontract storage lastLong = subcontracts[longTakerContracts[longTakerContracts.length - 1]];
            lastLong.index = index;
            longTakerContracts[index] = longTakerContracts[longTakerContracts.length - 1];
            longTakerContracts.pop();
        }
        Subcontract memory blank;
        subcontracts[subkID] = blank;
    }

    /** Settle the taker long sukcontracts
    * @param takerLongRets the returns for a long contract for a taker for each potential startDay
    * */
  function settleLong(int[8] memory takerLongRets, uint topLoop)
        public
        onlyAdmin
    {
        // long settle can only be done once at settlement
       require(settleNum < longTakerContracts.length);
       // settlement can only be done at least 5 days since the last settlement
       require(now > lastBookSettleTime + NO_DOUBLE_SETTLES);
       topLoop = min(longTakerContracts.length, topLoop);
        LPRequiredMargin = add(LPLongMargin,LPShortMargin);
         for (settleNum; settleNum < topLoop; settleNum++) {
             settleSubcontract(longTakerContracts[settleNum], takerLongRets);
        }
    }

    /** Settle the taker long sukcontracts
    * @param takerShortRets the returns for a long contract for a taker for each potential startDay
    * */
 function settleShort(int[8] memory takerShortRets, uint topLoop)
        public
        onlyAdmin
    {
        require(settleNum >= longTakerContracts.length);
        topLoop = min(shortTakerContracts.length, topLoop);
        for (uint i = settleNum - longTakerContracts.length; i < topLoop; i++) {
             settleSubcontract(shortTakerContracts[i], takerShortRets);
        }
        settleNum = topLoop + longTakerContracts.length;
        
        if (settleNum == longTakerContracts.length + shortTakerContracts.length) {
            LPMargin = subzero(LPMargin,debitAcct);
            if (LPShortMargin > LPLongMargin) LPRequiredMargin = subzero(LPShortMargin,LPLongMargin);
                else LPRequiredMargin = subzero(LPLongMargin,LPShortMargin);
            debitAcct = 0;
            lastBookSettleTime = now;
            settleNum = 0;
            if (LPMargin < LPRequiredMargin) {
                bookDefaulted = true;
                uint defPay = min(LPMargin, LPRequiredMargin/BURN_DEF_FEE);
                LPMargin = subzero(LPMargin,defPay);
            }
        }
    }

     function MarginCheck()
        public
        view
        returns (uint playerMargin, uint bookETH)
    {
        playerMargin = 0;

            for (uint i = 0; i < longTakerContracts.length; i++) {
             Subcontract storage k = subcontracts[longTakerContracts[i]];
             playerMargin = playerMargin + k.takerMargin ;
            }
             for (uint i = 0; i < shortTakerContracts.length; i++) {
             Subcontract storage k = subcontracts[shortTakerContracts[i]];
             playerMargin = playerMargin + k.takerMargin ;
            }

            playerMargin  = playerMargin + LPMargin;
            bookETH = address(this).balance;


    }

      /** Internal fn to settle an individual subcontract
    * @param subkID the id of the subcontract
    * @param subkRets the taker returns for a contract of that position for each day of the week
    */


    function settleSubcontract(bytes32 subkID, int[8] memory subkRets)
     internal
    {
        Subcontract storage k = subcontracts[subkID];
        // Don't settle terminated contracts or just starting subcontracts
        if (k.isActive && (k.startDay != 7)) {

            uint absolutePNL;

            bool lpprof;
            if (subkRets[k.startDay] < 0) {
                lpprof = true;
                absolutePNL = uint(-1 * subkRets[k.startDay]) * k.reqMargin / 1 finney;
            }
            else {
                absolutePNL = uint(subkRets[k.startDay]) * k.reqMargin / 1 finney;
            }
            absolutePNL = min(k.reqMargin,absolutePNL);
            if (lpprof) {
                k.takerMargin = subzero(k.takerMargin,absolutePNL);
                if (!k.takerBurned) LPMargin = add(LPMargin,absolutePNL);
            } else {
                if (absolutePNL>LPMargin) debitAcct = add(debitAcct,subzero(absolutePNL,LPMargin));
                LPMargin = subzero(LPMargin,absolutePNL);
                if (!k.LPBurned) k.takerMargin = add(k.takerMargin,absolutePNL);
            }
            if (k.LPBurned || k.takerBurned || k.isCancelled) {
                if (k.LPSide) LPLongMargin = subzero(LPLongMargin,k.reqMargin);
                else LPShortMargin = subzero(LPShortMargin,k.reqMargin);
                k.isActive = false;
            } else if (k.takerMargin < k.reqMargin)
            {
                if (k.LPSide) LPLongMargin = subzero(LPLongMargin,k.reqMargin);
                else LPShortMargin = subzero(LPShortMargin,k.reqMargin);
                k.isActive = false;
                k.takerDefaulted = true;
            }
        }
        k.startDay = 0;
    }


      /** Create a new Taker long subcontract of the given parameters
    * @param taker the address of the party on the other side of the contract
    * @param amount the amount in ETH to create the subcontract for
    * @param sizeDiscCut is level below which the taker pays a double closeing fee r
    * @param startDay is the first day of the initial week used to get the starting price
    * @param lastOracleSettleTime makes sure takes do not happen in settlement period
    * @return subkID the id of the newly created subcontract
	*/
	 function take(address taker, uint amount, uint sizeDiscCut, uint8 startDay, uint lastOracleSettleTime, bool takerLong)
        public
        payable
        onlyAdmin
        returns (bytes32 subkID)
    {
        require(amount * 1 finney >= minRM, "must be greater than book min");
   //     require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        Subcontract memory order;
        order.reqMargin = amount * 1 finney;
        order.takerMargin = msg.value;
        order.taker = taker;
        order.isActive = true;
        order.startDay = startDay;
        if (!takerLong) order.LPSide = true;
        if (takerLong) {
  //          require(longTakerContracts.length < MAX_SUBCONTRACTS, "bookMaxedOut");
            subkID = keccak256(abi.encodePacked(lp, now, longTakerContracts.length));  // need to add now
            order.index = longTakerContracts.length;
            longTakerContracts.push(subkID);
            LPShortMargin = add(LPShortMargin,order.reqMargin);
            if (subzero(LPShortMargin,LPLongMargin) > LPRequiredMargin)
                LPRequiredMargin = subzero(LPShortMargin,LPLongMargin);
            } else {
 //           require(shortTakerContracts.length < MAX_SUBCONTRACTS, "bookMaxedOut");
            subkID = keccak256(abi.encodePacked(shortTakerContracts.length,lp, now));  // need to add now
            order.index = shortTakerContracts.length;
            shortTakerContracts.push(subkID);
            LPLongMargin = add(LPLongMargin,order.reqMargin);
             if (subzero(LPLongMargin,LPShortMargin) > LPRequiredMargin)
            LPRequiredMargin = subzero(LPLongMargin,LPShortMargin);
             }
        if (add(LPLongMargin,LPShortMargin) >= sizeDiscCut) order.takerCloseDisc = true;
        subcontracts[subkID] = order;
        return subkID;
    }


     /** Withdraw margin from the LP margin
    * @param amount the amount of margin to move
    * @param lastOracleSettleTime timestamp of the last oracle setlement time
    * @notice reverts if during the settle period
    */
    function withdrawalLP(uint amount, uint lastOracleSettleTime)
        public
        onlyAdmin
    {
        if (bookDefaulted) {
            require (LPMargin >= amount, "Cannot withdraw more than the margin");
        } else {
            require (LPMargin >= add(LPRequiredMargin,amount),"Cannot to w/d more than excess margin");
            require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        }
        LPMargin = subzero(LPMargin,amount);
        balanceSend(amount, lp);
    }

    /** Allow a taker to withdraw margin
    * @param subkID the subcontract id
    * @param lastOracleSettleTime the block timestamp of the last oracle settle price
    * @param sender who sent this message to AssetSwap
    * @notice reverts during settle period
    */
    function withdrawalTaker(bytes32 subkID, uint amount, uint lastOracleSettleTime, address sender)
        public
        onlyAdmin
    {
        require(lastOracleSettleTime < lastBookSettleTime, "Cannot do during settle period");
        Subcontract storage k = subcontracts[subkID];
        require(k.takerMargin >= add(k.reqMargin,amount),"must have sufficient margin");
        require(sender == k.taker, "Must be taker to call this function");
        k.takerMargin = subzero(k.takerMargin,amount);
        balanceSend(amount, k.taker);
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

    function add(uint _a, uint _b)
        internal
        pure
        returns (uint)
        {
        uint c = _a + _b;
        assert(c >= _a);
        return c;
        }

}

