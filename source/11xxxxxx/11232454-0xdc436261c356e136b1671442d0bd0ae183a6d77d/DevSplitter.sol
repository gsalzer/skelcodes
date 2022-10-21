// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Address.sol";

contract DevSplitter
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    mapping (IERC20 => uint256) public totalPaid;
    mapping (IERC20 => mapping(address => uint256)) public totalPaidToPayee;
    
    mapping (address => uint256) public share;
    uint256 immutable public totalShares;

    constructor(address[] memory payees, uint256[] memory shares)
    {
        require (payees.length == shares.length && payees.length > 0);

        uint256 total = 0;
        for (uint256 x=0; x<payees.length; ++x) {
            address payee = payees[x];
            uint256 sh = shares[x];
            require (payee != address(0) && sh > 0 && share[payee] == 0);
            require (!payee.isContract(), "Cannot pay a contract");
            total = total.add(sh);
            share[payee] = sh;
        }
        totalShares = total;
    }

    receive() external payable {}

    function owed(IERC20 token, address payee) public view returns (uint256) {        
        uint256 balance = address(token) == address(0) ? address(this).balance : token.balanceOf(address(this));
        uint256 payeeShare = balance.add(totalPaid[token]).mul(share[payee]) / totalShares;
        uint256 paid = totalPaidToPayee[token][payee];
        return payeeShare > paid ? payeeShare - paid : 0;
    }

    function pay(IERC20 token, address payable payee) public {
        uint256 toPay = owed(token, payee);
        require (toPay > 0, "Nothing to pay");

        totalPaid[token] = totalPaid[token].add(toPay);
        totalPaidToPayee[token][payee] = totalPaidToPayee[token][payee].add(toPay);
                
        if (address(token) == address(0)) {
            (bool success,) = payee.call{ value: toPay }("");
            require (success, "Transfer failed");
        }
        else {
            token.safeTransfer(payee, toPay);
        }
    }
}
