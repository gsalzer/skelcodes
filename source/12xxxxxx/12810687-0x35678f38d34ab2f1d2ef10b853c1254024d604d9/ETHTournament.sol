// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";

contract ETHTournament is Ownable{
    using SafeMath for uint256;

    address payable[] public players;
    uint256[] public p;
    uint256 fee;
    uint256 min;

    constructor(uint256 _fee, uint256 _min) {
        fee=_fee;
        min=_min;
    }

    function createResult(uint256[] memory _p) onlyOwner public {
        require(getSum(_p)<=100);
        p=_p;
    }

    function EnterETH() payable public {
        require(msg.value>=min);
        players.push(payable(msg.sender));
    }

    function dividePrizeETH() payable onlyOwner public {
        for(uint256 j=0;j<p.length;j++){
            players[j].transfer((address(this).balance).mul(p[j]).div(100));
        }
    }

    function BalanceofTournament() public view returns(uint256 _balance){
        return address(this).balance;
    }

    function getSum(uint256[] memory arr) public pure returns(uint256 _sum) {
        uint256 i;
        uint256 sum = 0;

        for(i = 0; i < arr.length; i++)
            sum = sum + arr[i];
        return sum;
    }

    function Cost(address payable costaddress) onlyOwner public{
        costaddress.transfer(fee);
    }
}

