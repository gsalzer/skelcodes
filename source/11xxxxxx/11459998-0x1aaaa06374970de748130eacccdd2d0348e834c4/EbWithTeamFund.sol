// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibBaseAuth.sol";


contract WithTeamFund is BaseAuth {
    address payable[8] private _teamFunds;
    uint8 private _fp;

    function setTeamFunds(address payable[8] memory accounts)
        external
        onlyAgent
    {
        for (uint8 i = 0; i < 8; i++)
        {
            _teamFunds[i] = accounts[i];
        }
    }
    
    function sendTeamFund()
        internal
    {
        address payable fund = _teamFunds[_fp % 8];
        if (fund != address(0)) {
            fund.transfer(address(this).balance);
        }
        _fp++;
    }
}

