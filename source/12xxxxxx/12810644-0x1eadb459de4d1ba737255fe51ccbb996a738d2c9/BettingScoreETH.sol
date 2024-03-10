// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract BettingScoreETH is Ownable{
    using SafeMath for uint256;
    struct Info {
        address payable player;
        uint256 home;
        uint256 away;
        uint256 amount;
    }

    uint256 public score1;
    uint256 public score2;
    uint256 public count;
    uint256 public min;
    uint256 public fee;
    address trustedOracle;
    bool finishResult=false;
    bool finishEnter=false;
    mapping (uint256=>Info) info;

    constructor(uint256 _min, uint256 _fee){
        min=_min;
        fee=_fee;
    }

    modifier onlyTrustedOracle() {
        require(msg.sender == trustedOracle);
        _;
    }

    function setTrustedOracle(address _oracle) onlyOwner public{
        trustedOracle = _oracle;
    }

    event LogOracle();
    event LogEntering(uint256 _score1, uint256 _score2);
    event LogEnterGame(uint256 _home, uint256 _away);
    event LogDistribution();

    function setResult() public {
        emit LogOracle();
    }

    function __callback(uint256 _score1, uint256 _score2) public onlyTrustedOracle{
        score1 = _score1;
        score2 = _score2;
        finishResult = true;
        emit LogEntering(_score1, _score2);
    }

    function EnterGame(uint256 _home, uint256 _away) payable public{
        require(finishResult==false);
        require(msg.value>=min);
        Info storage c = info[count];
        c.player=payable(msg.sender);
        c.home=_home;
        c.away=_away;
        c.amount=msg.value;
        count+=1;

        emit LogEnterGame(_home, _away);
    }

    function Distribution() onlyOwner public{
        require(finishResult==true);
        uint256 WinnerAmount;
        for(uint256 i=0;i<count;i++){
            Info storage c = info[i];
            if(c.home==score1&&c.away==score2){
                WinnerAmount+=c.amount;
            }
        }

        for(uint256 i=0;i<count;i++){
            Info storage c = info[i];
            if(c.home==score1&&c.away==score2){
                (c.player).transfer((c.amount).div(WinnerAmount).mul(address(this).balance));
            }
        }

        emit LogDistribution();
    }

    function Cost(address payable costaddress) onlyOwner public{
        costaddress.transfer(fee);
    }
}

