// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";

contract BettingOXETH is Ownable{
    using SafeMath for uint256;
    struct Info {
        address payable player;
        bool home;
        uint256 amount;
    }

    bool public homewin;
    uint256 public count;
    uint256 public countwin;
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
    event LogEntering(bool _homewin);
    event LogEnterGame(bool _home);
    event LogDistribution();

    function setResult() public {
        emit LogOracle();
    }

    function __callback(bool _homewin) public onlyTrustedOracle{
        homewin=_homewin;
        finishResult = true;
        emit LogEntering(_homewin);
    }

    function EnterGame(bool _home) payable public{
        require(finishResult==false);
        require(msg.value>=min);
        Info storage c = info[count];
        c.player=payable(msg.sender);
        c.home=_home;
        c.amount=msg.value;
        count+=1;
        if(c.home==true){
            countwin+=msg.value;
        }
        emit LogEnterGame(_home);
    }

    function Distribution() onlyOwner public{
        require(finishResult==true);
        for(uint256 i=0;i<count;i++){
            Info storage c = info[i];
            if(c.home==true&&c.home==homewin){
                (c.player).transfer((c.amount).div(countwin).mul(address(this).balance));
            }
            else if(c.home=false&&c.home==homewin){
                (c.player).transfer((c.amount).div(address(this).balance.sub(countwin)).mul(address(this).balance));
            }
        }

        emit LogDistribution();
    }

    function Cost(address payable costaddress) onlyOwner public{
        costaddress.transfer(fee);
    }
}

