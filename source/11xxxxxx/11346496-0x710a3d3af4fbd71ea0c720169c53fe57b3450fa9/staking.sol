// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.5;

import './cubecoin.sol';


interface IStaking{
    
    function stake() external returns(bool);
    
    function claim() external returns(bool);
    
    function forceclaim() external returns(bool);
    
    function drain() external returns(bool);
    
    function specificDrain(uint256 amount) external returns(bool);
    
    function fetchhistory(address user) external returns(uint256[],uint256[],uint256[]);
    
}

contract CUB_STAKING {
    Cubebit public cube_address;
    address public owner;
    
    struct History{
        uint256[] time;
        uint256[] amount;
        bool[] isclaimed;
    }
    
    
    struct User{
        uint256 staked;
        uint256 claimed;
        uint256 laststake;
    }
    
    constructor(address contract_address) public{
        cube_address = Cubebit(contract_address);
        owner = msg.sender;
    }
    
    mapping(address => User) public users;
    mapping(address => History) history;
    
    function stake(uint256 _amount) public returns(bool){
        require(cube_address.allowance(msg.sender,address(this)) >= _amount,'Allowance Exceeded');
        require(cube_address.balanceOf(msg.sender) >= _amount,'Insufficient Balance');
        User storage u = users[msg.sender];
        u.staked = SafeMath.add(u.staked,_amount);
        u.laststake = block.timestamp;
        History storage h = history[msg.sender];
        h.time.push(block.timestamp);
        h.amount.push(_amount);
        h.isclaimed.push(false);
        cube_address.transferFrom(msg.sender,address(this),_amount);
        return true;
    }
    
    function claim() public returns(bool,uint256){
        User storage u = users[msg.sender];
        require(u.staked > 0, 'Nothing Staked');
        require(block.timestamp > u.laststake + 365 days,'Maturity Not Reached');
        uint256 p = SafeMath.mul(u.staked,12);
        uint256 i = SafeMath.div(p,100);
        uint256 am = SafeMath.add(u.staked,i);
        History storage h = history[msg.sender];
        h.time.push(block.timestamp);
        h.amount.push(am);
        h.isclaimed.push(true);
        u.claimed = SafeMath.add(u.claimed,am);
        u.staked = 0;
        u.laststake = 0;
        cube_address.transfer(msg.sender,am);
        return(true,am);
    }
    
    function forceclaim() public returns(bool){
        User storage u = users[msg.sender];
        require(u.staked > 0,'Nothing Staked');
        u.claimed = SafeMath.add(u.claimed,u.staked);
        History storage h = history[msg.sender];
        h.time.push(block.timestamp);
        h.amount.push(u.staked);
        h.isclaimed.push(true);
        cube_address.transfer(msg.sender,u.staked);
        u.staked = 0;
        u.laststake = 0;
        return true;
    }
    
    function fetchhistory(address user) public view returns(uint256[] time,uint256[] staked,bool[] claimed){
        History storage h = history[user];
        return(h.time,h.amount,h.isclaimed);
    }
    
    function changeOwner(address new_owner) public returns(bool){
        require(msg.sender==owner,'Not Owner');
        owner = new_owner;
    }
    
    function drain() public returns(bool){
        require(msg.sender==owner,'Not Owner');
        cube_address.transfer(owner,cube_address.balanceOf(address(this)));
    }
    
    function specificDrain(uint256 amount) public returns(bool){
        require(msg.sender==owner,'Not Owner');
        cube_address.transfer(owner,amount);
    }
    
}
