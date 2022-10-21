// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./eGI.sol";
import "./SafeMath.sol";

contract TokenTournament is Ownable{
    event enter(uint256 amount);
    event diviedPrize();

    using SafeMath for uint256;

    eGIToken token;
    address payable[] public players;
    uint256[] public p;
    uint256 percent;
    uint256 fee;
    uint256 min;


    constructor(uint256 _fee, uint256 _min, eGIToken _token) {
        fee=_fee;
        token=_token;
        min=_min;
    }

    function createResult(uint256[] memory _p) onlyOwner public {
        require(getSum(_p)<=100);
        p=_p;
    }

    function EnterToken(uint256 amount) public {
        require(amount>=min);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        players.push(payable(msg.sender));
        token.transferFrom(msg.sender, address(this), amount);

        emit enter(amount);
    }

    function diviedPrizeToken() onlyOwner public{
        for(uint256 j=0;j<p.length;j++){
            token.transfer(players[j], (token.balanceOf(address(this))).mul(p[j]).div(100));
        }

        emit diviedPrize();
    }

    function BalanceofTournament() public view returns(uint256 _balance){
        return token.balanceOf(address(this));
    }

    function getSum(uint256[] memory arr) public pure returns(uint256 _sum) {
        uint256 i;
        uint256 sum = 0;

        for(i = 0; i < arr.length; i++)
            sum = sum + arr[i];
        return sum;
    }

    function Cost(address payable costaddress) onlyOwner public{
        token.transfer(costaddress, fee);
    }
}

