// SPDX-License-Identifier: UNLICENSED

pragma solidity <=0.7.5;

import './bundle_token.sol';

contract Bundles {
    
    uint256 public bundleId = 2;
    address public owner;
    TokenMintERC20Token public bundle_address;
    
    uint256 public lastcreated;
    uint256 lastbundlecreated;

    struct UserBets{
        uint256[10] bundles;
        uint256[10] amounts;
        uint256[10] prices;
        bool betted;
        uint256 balance;
        uint256 totalbet;
        bool claimed;
    }
    
    struct User{
        uint256[] bundles;
        string username;
        uint256 balance;
        uint256 freebal;
        bool active;
    }
    
    struct Data{
        address[] user;
    }
    
    struct Bundle{
        uint256[10] prices;
        uint256 startime;
        uint256 stakingends;
        uint256 endtime;
    }
    
    mapping(address => mapping(uint256 => UserBets)) bets;
    mapping(uint256 => Bundle) bundle;
    mapping(address => User) user;
    mapping(uint256 => Data) data;
    
    constructor(address _bundle_address) public{
        owner = msg.sender;
        bundle_address = TokenMintERC20Token(_bundle_address);
        lastcreated = block.timestamp;
    }
    
    function Register(string memory _username) public returns(bool){
        User storage us = user[msg.sender];
        require(us.active == false,'Existing User');
        us.active = true;
        us.username = _username;
        return true;
    }
    
    function PlaceBet(uint256 index,uint256 _prices,uint256 _percent,uint256 _bundleId,uint256 _amount) public returns(bool){
        require(_bundleId <= bundleId,'Invalid Bundle');
        require(bundle_address.allowance(msg.sender,address(this))>=_amount,'Approval failed');
        Bundle storage b = bundle[_bundleId];
        Data storage d = data[_bundleId];
        require(b.stakingends >= block.timestamp,'Ended');
        User storage us = user[msg.sender];
        require(us.active == true,'Register to participate');
        UserBets storage u = bets[msg.sender][_bundleId];
        require(u.bundles[index] == 0,'Already Betted');
        if(u.betted == false){
            u.balance = bundle_address.balanceOf(msg.sender);
            u.betted = true;
        }
        else{
            require(SafeMath.add(u.totalbet,_amount) <= u.balance,'Threshold Reached');
        }
        us.bundles.push(_bundleId);
        us.balance = SafeMath.add(us.balance,_amount);
        u.bundles[index] = _percent; 
        u.prices[index] = _prices; 
        u.amounts[index] = _amount;
        u.totalbet = u.totalbet + _amount;
        d.user.push(msg.sender);
        bundle_address.transferFrom(msg.sender,address(this),_amount);
        return true;
    }
    
    
    function updatebal(address _user,uint256 _bundleId,uint256 _reward,bool _isPositive) public returns(bool){
        require(msg.sender == owner,'Not Owner');
        require(_reward <= 25000000,'Invalid Reward Percent');
        User storage us = user[_user];
        require(us.active == true,'Invalid User');
        UserBets storage u = bets[_user][_bundleId];
        require(u.claimed == false,'Already Claimed');
        uint256 a = SafeMath.mul(u.totalbet,_reward);
        uint256 b = SafeMath.div(a,10**8);
        if(_isPositive == true){
            uint256 c = SafeMath.add(u.totalbet,b);
            u.claimed = true;
            us.freebal = SafeMath.add(c,us.freebal);
            us.balance = SafeMath.sub(us.balance,u.totalbet);
        }
        else{
            uint256 c = SafeMath.sub(u.totalbet,b);
            u.claimed = true;
            us.freebal = SafeMath.add(c,us.freebal);
            us.balance = SafeMath.sub(us.balance,u.totalbet);
        }
        return true;
    }
    
    function createBundle(uint256[10] memory _prices) public returns(bool){
        require(msg.sender == owner,'Not Owner');
        require( block.timestamp > lastbundlecreated +  2 days,'Cannot Create');
        Bundle storage b = bundle[bundleId];
        b.prices = _prices;
        b.startime = block.timestamp;
        lastbundlecreated = block.timestamp;
        lastcreated = block.timestamp;
        b.endtime = SafeMath.add(block.timestamp,2 days);
        b.stakingends = SafeMath.add(block.timestamp,1 days);
        bundleId = SafeMath.add(bundleId,1);
        return true;
    }
    
    function updateowner(address new_owner) public returns(bool){
        require(msg.sender == owner,'Not an Owner');
        owner = new_owner;
        return true;
    }
    
    function updatetime(uint256 _timestamp) public returns(bool){
        require(msg.sender == owner,'Not an owner');
        lastcreated =  _timestamp;
    }
    
    function withdraw() public returns(bool){
       User storage us = user[msg.sender];
       require(us.active == true,'Invalid User'); 
       require(us.freebal > 0,'No bal');
       bundle_address.transfer(msg.sender,us.freebal);
       us.freebal = 0;
       return true;
    }
    
    function fetchUser(address _user) public view returns(uint256[] memory _bundles,string memory username,uint256 claimable,uint256 staked_balance, bool active){
        User storage us = user[_user];
        return(us.bundles,us.username,us.freebal,us.balance,us.active);
    }
    
    function fetchBundle(uint256 _bundleId) public view returns(uint256[10] memory _prices,uint256 _start,uint256 _end,uint256 _staking_ends){
        Bundle storage b = bundle[_bundleId];
        return(b.prices,b.startime,b.endtime,b.stakingends);
    }
    
    function fetchUserBets(address _user, uint256 _bundleId) public view returns(uint256[10] memory _bundles,uint256[10] memory _prices,uint256[10] memory _amounts,uint256 balance,uint256 totalbet){
        UserBets storage u = bets[_user][_bundleId];
        return (u.bundles,u.prices,u.amounts,u.balance,u.totalbet);
    }
    
    function fetchUserInBundle(uint256 _bundleId) public view returns(address[] memory _betters){
        Data storage d = data[_bundleId];
        return d.user;
    }
    
    function drain() public returns(bool,uint256){
        require(msg.sender == owner,'Not Owner');
        uint256 amount = bundle_address.balanceOf(address(this));
        bundle_address.transfer(msg.sender,amount);
        return(true,amount);
    }
    
}
