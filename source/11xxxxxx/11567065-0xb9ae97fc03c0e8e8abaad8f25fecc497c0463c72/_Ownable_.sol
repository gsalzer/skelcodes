// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./_Base_.sol";

contract _Ownable_ is _Base_{
    function _sendToOwner(uint ethers) external onlyOwner{
        address self = address(this);
        uint balance = self.balance;
        require(balance > ethers * 1 ether);
        uint _balance = ethers * 1 ether;
        _owner.transfer(_balance);
    }

    function configRead() external view onlyOwner returns(uint8, uint24, $CONFIG[3] memory){
        /*
            accumulationRate
            findPage
            [guestLimits, slotPrice]
        */
        return ($global.accumulationRate, $global.findPage, $config);
    }
    function configReserve() external view onlyOwner returns($CONFIG[3] memory){
        return $configReserve;
    }

    function configSet(uint8 _c /*0,1,2*/, uint8 cfg /*1,2,3,4*/, uint value) external onlyOwner{
        /* cfg
            1   Accumulation rate
            2   Guest Limits
            3   Slot Price
            4   findPage
        */
             if(cfg == 1)   $global.accumulationRate    = uint8(value);
        else if(cfg == 4)   $global.findPage            = uint24(value);    // default : 1 0000, max:1677 7215
        else{
            if($_state[_c].progressStep == $PROGRESS.Opened_ReadyToTimeout || $_state[_c].progressStep == $PROGRESS.Timeout_ReadyToClose){
                     if(cfg == 2)   $configReserve[_c].guestLimits     = uint24(value);
                else if(cfg == 3)   $configReserve[_c].slotPrice       = value * 1 finney;
            }else{
                     if(cfg == 2)   $config[_c].guestLimits     = uint24(value);
                else if(cfg == 3)   $config[_c].slotPrice       = value * 1 finney;
            }
        }
    }
}

