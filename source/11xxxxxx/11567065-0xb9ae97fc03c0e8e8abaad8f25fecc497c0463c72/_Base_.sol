// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;

contract _Base_{
    // new
    address payable internal _owner;
    modifier onlyOwner      {require(msg.sender == _owner); _;}

    struct $GLOBAL{
        uint8   accumulationRate;    // 70   : 70%
        uint24  findPage;   // max 1677 7215
    }
    $GLOBAL $global;

    struct $CONFIG{
        uint24  guestLimits;    // 500  : 500 * 10000 => * 1000
        uint    slotPrice;      // fix 0.1 ether, units finney
    }
    $CONFIG[3] $config;
    $CONFIG[3] $configReserve;

    enum $PROGRESS{
        ReadyToOpen,            // 0    ! -> boardOpen()
        Opened_ReadyToTimeout,  // 1    boardOpen() -> ! -> needToTimeout() - yes : timeoutStart(), no : waiting detect
        Timeout_ReadyToClose,   // 2    timeoutStart() -> ! -> needToStop() ? boardClose() : waiting
        Closed_MakeWeights,     // 3    boardClose() -> ! -> closingMakeWeights()
        Weighted_FindWinners,   // 4    closingMakeWeights() -> ! -> closingFindWinner()
        FindAndAddWinners       // 5    closingFindWinner(), closingAddWinner() -> ! winners ? closingRewards() : closingCarryOver()
        /* 
            when FindAndAddWinners finished
                no guest -> closingCarryOver() ->  ready to open
                no winners -> closingCarryOver() ->  ready to open
                some winners -> closingRewards() ->  ready to open
        */
    }
    
    struct $STATE{
        $PROGRESS   progressStep;

        uint32      dateStart;
        uint32      dateExpiry; // 42 9496 7295
        uint24      turn;
        
        bool        carryOver;
        uint256     fullAmounts;
        uint256[45] weights;   // max 45, index 0~44, value:1~45
    }
    $STATE[3]      $_state;
    modifier whenNotRunning(uint8 _c){
        require($_state[_c].progressStep != $PROGRESS.Opened_ReadyToTimeout && $_state[_c].progressStep != $PROGRESS.Timeout_ReadyToClose);
        _;
    }
    modifier whenRunning(uint8 _c){
        require($_state[_c].progressStep == $PROGRESS.Opened_ReadyToTimeout || $_state[_c].progressStep == $PROGRESS.Timeout_ReadyToClose);
        _;
    }
    

    // [ guest ]
    mapping(address => uint)        _guestDeposits;

    struct $SLOT{
        // 0 : nothing, 1~35 or 40 or 45
        uint8       vote;
        uint8[6]    numbers;
    }
    struct $VOTE{
        uint24      turn;
        $SLOT[5]    slot;
    }
    struct $GUESTS{
        address[]                   lists;  // participation
        mapping(address => $VOTE)   votes;
    }
    $GUESTS[3]  $guests;    // 0,1,2 : 35,40,45

    struct LASTGAME_WINNER{
        address     wallet;
        uint8[6]    numbers;
    }
    struct LASTGAME{
        bool        carryOver;
        uint24      turn;
        uint8[6]    winNumbers;
        uint        rewardsFull;
        uint        rewards6Each;
        uint        rewards5Each;
        uint        rewards4Each;
        uint        carryOverAmount;
        
        uint8       closingStep;
        /* closingStep
            0 - boardClose()                                    -> making weights
            1 - closingMakeWeights()                            -> finding winners(add winners)
              - closingFindWinner(), if winner closingAddWinner -> compelete finding
            2 - if winners, closingRewards()                    -> compeleted closing, ready to open
                if no winners, closingCarryOver()               -> compeleted closing, ready to open
        */

        LASTGAME_WINNER[]   winners6;
        LASTGAME_WINNER[]   winners5;
        LASTGAME_WINNER[]   winners4;
    }
    LASTGAME[3] _lastgame;

    struct WINNER{
        uint8           category;
        uint24          turn;
        uint8[6]        winNumbers; //  turn numbers
        uint            toBePaid;   // rewards, wei
        uint32          datetime;
        LASTGAME_WINNER guest;
    }
    WINNER[]    _waitingList;
    WINNER[]    _withdrawedList;

// [ ■■■ internal utilities ■■■ 
// ] ■■■ internal utilities ■■■ 
}

