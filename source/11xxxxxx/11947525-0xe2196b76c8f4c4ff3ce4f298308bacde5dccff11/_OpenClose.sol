// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./_Base_.sol";

contract _OpenClose is _Base_{
    // [ ■■■ open ■■■
    function boardOpen(uint8 _c /*0,1,2*/) external onlyOwner whenNotRunning(_c){
        // clear last data
        delete $guests[_c];
        
        uint24 turn = $_state[_c].turn;

        // reset to new game
        $STATE memory c;
        $_state[_c]             = c;
        $_state[_c].progressStep= $PROGRESS.Opened_ReadyToTimeout;  // ReadyToOpen:0 -> set 1
        $_state[_c].dateStart   = uint32(block.timestamp);
        $_state[_c].turn        = turn + 1;

        // add last carried over
        if(_lastgame[_c].carryOver){
            $_state[_c].fullAmounts         = _lastgame[_c].carryOverAmount;
            _lastgame[_c].carryOverAmount   = 0;
            _lastgame[_c].carryOver         = false;
        }
    }
    // ] ■■■ open ■■■

    // [ ■■■ with closing ■■■
    function timeoutStart(uint8 _c, uint8 _day)external onlyOwner{
        require($_state[_c].progressStep != $PROGRESS.Timeout_ReadyToClose);
        
        $_state[_c].dateExpiry      = uint32(block.timestamp) + _day * 1 days;
        $_state[_c].progressStep    = $PROGRESS.Timeout_ReadyToClose;   // Opened_ReadyToTimeout:1 -> 2
    }
    // ] ■■■ with closing ■■■

    // [ ■■■ close ■■■
    function boardClose(uint8 _c /*0,1,2*/) external onlyOwner whenRunning(_c){
        if($configReserve[_c].guestLimits != 0) {$config[_c].guestLimits = $configReserve[_c].guestLimits;  $configReserve[_c].guestLimits = 0;}
        if($configReserve[_c].slotPrice != 0)   {$config[_c].slotPrice = $configReserve[_c].slotPrice;      $configReserve[_c].slotPrice = 0;}

        $_state[_c].progressStep    = $PROGRESS.Closed_MakeWeights; // Timeout_ReadyToClose:2 -> 3

        delete _lastgame[_c];
        _lastgame[_c].turn = $_state[_c].turn;
        _lastgame[_c].closingStep = 0;
    }
    
    function closingMakeWeights(uint8 _c /*0,1,2*/) external onlyOwner whenNotRunning(_c){
        $_state[_c].progressStep    = $PROGRESS.Weighted_FindWinners;   // Closed_MakeWeights:3 -> 4
        _lastgame[_c].winNumbers    = $orders($winNumbers(_c));
        _lastgame[_c].closingStep   = 1;
    }

    uint[3] $seekPosition;
    function closingSetFinding(uint8 _c /*0,1,2*/) external onlyOwner whenNotRunning(_c){
        // set finding, before first finding
        $_state[_c].progressStep    = $PROGRESS.FindAndAddWinners; // 4 -> 5 : closingFindWinner(), closingAddWinner()
        $seekPosition[_c] = 0;
    }
    modifier whenFinding(uint8 _c){
        require($_state[_c].progressStep == $PROGRESS.FindAndAddWinners);
        _;
    }
    function closingSetSeek(uint8 _c /*0,1,2*/, uint _s) external onlyOwner whenFinding(_c){
        $seekPosition[_c] = _s;
    }
    function closingFindWinner(uint8 _c /*0,1,2*/)external view onlyOwner whenFinding(_c)
        returns(uint toLast, bool found, uint winnerIndex){

        if($guests[_c].lists.length == 0)   return (0, false, 0);
        if(_lastgame[_c].winNumbers[0] == 0)return (0, false, 0);

        uint _to = $seekPosition[_c] + $global.findPage;
        if(_to > $guests[_c].lists.length) _to = $guests[_c].lists.length;

        for(uint i = $seekPosition[_c]; i < _to; i++){
            address guest = $guests[_c].lists[i];
            $SLOT[5] memory $slots = $guests[_c].votes[guest].slot;
            for(uint8 s = 0; s < 5; s++){
                uint8 matchCount = $matchCount(_c, $slots[s].numbers);
                if(matchCount > 3) return (i, true, i); /* matches 4,5,6 */
            }
        } // for
        return (_to - 1, false, 0);
    }
    
    // call this, only when $PROGRESS.FindAndAddWinners
    address $addedAddress;
    uint8   $addedSlot;
    function closingAddWinner(uint8 _c /*0,1,2*/, uint guestIndex) external onlyOwner whenNotRunning(_c){
        address guest = $guests[_c].lists[guestIndex];
        require($_state[_c].turn == $guests[_c].votes[guest].turn);

        bool[5] memory  slots   = [false, false, false, false, false];
        uint8[5] memory matches = [0,0,0,0,0];
        bool            matched = false;
        $SLOT[5] memory $slots  = $guests[_c].votes[guest].slot;

        for(uint8 s=0; s<5; s++){
            uint8 matchCount = $matchCount(_c, $slots[s].numbers);
            if(matchCount > 3){/* matches 4,5,6 */
                matched     = true;
                slots[s]    = true;
                matches[s]  = matchCount;
            }
        }
        require(matched); // exit when no matches

        for(uint8 s=0; s<5; s++){
            if(slots[s] == true && matches[s] > 3){
                LASTGAME_WINNER memory $g = LASTGAME_WINNER(guest, $slots[s].numbers);
                if($addedAddress != guest || $addedSlot != s){
                         if(matches[s] == 6) _lastgame[_c].winners6.push($g);
                    else if(matches[s] == 5) _lastgame[_c].winners5.push($g);
                    else                     _lastgame[_c].winners4.push($g);
                }
                $addedAddress   = guest;
                $addedSlot      = s;
            }
        }
    }
    
    /*  on finished $PROGRESS.FindAndAddWinners
        no guest -> closingCarryOver()
        some winners -> closingRewards()
        no winners -> closingCarryOver()
    */
    function closingCarryOver(uint8 _c /*0,1,2*/) external onlyOwner whenNotRunning(_c){
        // when no winners
        _lastgame[_c].rewardsFull       = 0;
        _lastgame[_c].rewards6Each       = 0;
        _lastgame[_c].rewards5Each       = 0;
        _lastgame[_c].rewards4Each       = 0;
        _lastgame[_c].carryOver         = true;
        _lastgame[_c].carryOverAmount   = $_state[_c].fullAmounts;

        _lastgame[_c].closingStep       = 2;
        $_state[_c].progressStep        = $PROGRESS.ReadyToOpen;
    }

    function closingRewards(uint8 _c /*0,1,2*/) external onlyOwner whenNotRunning(_c){
        _lastgame[_c].carryOver       = false;
        _lastgame[_c].carryOverAmount = 0;
        _lastgame[_c].rewardsFull     = $_state[_c].fullAmounts;

        uint _rewards = _lastgame[_c].rewardsFull / 100 * $global.accumulationRate;  // 70%
        
        uint24 w6count = uint24(_lastgame[_c].winners6.length);
        uint24 w5count = uint24(_lastgame[_c].winners5.length);
        uint24 w4count = uint24(_lastgame[_c].winners4.length);
        uint24 z6count = w6count;
        uint24 z5count = w5count;
        if(w4count > 0) z5count++;
        if(z5count > 0) z6count++;
        
        _lastgame[_c].rewards6Each = _rewards / z6count;
        _lastgame[_c].rewards5Each = (z5count == 0) ? 0 : _lastgame[_c].rewards6Each / z5count;
        _lastgame[_c].rewards4Each = (w4count == 0) ? 0 : _lastgame[_c].rewards5Each / w4count;

        $addWaitings(_c, w6count, 6);
        $addWaitings(_c, w5count, 5);
        $addWaitings(_c, w4count, 4);

        _lastgame[_c].closingStep   = 2;
        $_state[_c].progressStep    = $PROGRESS.ReadyToOpen;
    }
    // ] ■■■ close ■■■

// [ ■■■ private utilities ■■■ 
    function $addWaitings(uint8 _c /*0,1,2*/, uint24 _cnt, uint8 _matched) private{
        for(uint i = 0; i < _cnt; i++){
            WINNER memory winner;
            winner.category     = _c;
            winner.turn         = _lastgame[_c].turn;
            winner.winNumbers   = _lastgame[_c].winNumbers;
            if(_matched == 4){
                winner.guest    = _lastgame[_c].winners4[i];
                winner.toBePaid = _lastgame[_c].rewards4Each;
            }else if(_matched == 5){
                winner.guest    = _lastgame[_c].winners5[i];
                winner.toBePaid = _lastgame[_c].rewards5Each;
            }else{
                winner.guest    = _lastgame[_c].winners6[i];
                winner.toBePaid = _lastgame[_c].rewards6Each;
            }

            winner.datetime     = uint32(block.timestamp);
            _waitingList.push(winner);
        }
    }

    function $winNumbers(uint8 _c) private view returns(uint8[6] memory wins){
        // return 1 base
        // no wins when return any 0
        uint top = $higherTop($_state[_c].weights);
        if(top == 0) return wins;
        
        uint[6] memory highers;
        highers[0] = top;
        highers[1] = $higher($_state[_c].weights, highers[0]);
        highers[2] = $higher($_state[_c].weights, highers[1]);
        highers[3] = $higher($_state[_c].weights, highers[2]);
        highers[4] = $higher($_state[_c].weights, highers[3]);
        highers[5] = $higher($_state[_c].weights, highers[4]);
        
        uint8 count = 0;
        for(uint8 i=0; i<6; i++){
            if(highers[i] != 0){
                for(uint8 j=0; j<45; j++){
                    if(highers[i] == $_state[_c].weights[j]){
                        wins[count] = j + 1;
                        count++;
                        if(count == 6) break;
                    }
                }
            }
            if(count == 6) break;
        }
    }

    function $higherTop(uint[45] memory numbers) private pure returns(uint _w){
        uint v = 0;
        for(uint8 i=0; i<45; i++) if(numbers[i] > v) v = numbers[i];
        return v;
    }
    function $higher(uint[45] memory numbers, uint under) private pure returns(uint _w){
        uint v = 0;
        for(uint8 i=0; i<45; i++) if(numbers[i] < under && numbers[i] > v) v = numbers[i];
        return v;
    }
    function $orders(uint8[6] memory _n) private pure returns(uint8[6] memory){
        uint8[6] memory _o;
        uint8 last = 0;
        for(uint8 i=0; i<6; i++) if(_n[i] > last) last = _n[i];
        _o[5] = last;
        
        for(uint8 _index = 0; _index < 5; _index++){
            uint8 index = 5 - _index;
            last = 0;
            for(uint8 i=0; i<6; i++) if(_n[i] < _o[index] && _n[i] > last) last = _n[i];
            _o[index - 1] = last;
        }
        return _o;
    }
    
    function $matchCount(uint8 _c /*0,1,2*/, uint8[6] memory numbers)private view returns(uint8){
        uint8 count;
        for(uint8 w=0; w<6; w++){
            for(uint8 i=0; i<6; i++){
                if(_lastgame[_c].winNumbers[w] == numbers[i]) count++;
            }
        }
        return count;
    }

// ]  ■■■ private utilities ■■■ 

}

