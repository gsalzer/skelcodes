// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibSafeMath.sol";
import "LibBaseAuth.sol";


contract WithResaleFund is BaseAuth {
    using SafeMath for uint256;
    
    address payable private _resaleFund;
    uint16 private _resalePermille;

    function setResaleFund(
        address payable account,
        uint16 permille
    )
        external
        onlyAgent
    {
        require(permille <= 500, "Set resale fund permille: exceeds 50.0%");

        _resaleFund = account;
        _resalePermille = permille;
    }
    
    function getResaleFund()
        public
        view
        returns (
            address payable account,
            uint16 permille,
            uint256 balance
        )
    {
        account = _resaleFund;
        permille = _resalePermille;
        balance = account.balance;
    }

    function sendResaleFund(uint256 weiPayment)
        internal
    {
        if (_resalePermille > 0 && _resaleFund != address(0)) {
            _resaleFund.transfer(weiPayment.mul(_resalePermille).div(1_000));
        }
    }
}


