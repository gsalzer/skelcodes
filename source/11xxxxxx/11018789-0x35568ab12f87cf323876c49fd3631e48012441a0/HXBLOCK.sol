pragma solidity 0.6.4;

import "./SafeMath.sol";
import "./IERC20.sol";

////////////////////////////////////////////////
////////////////////EVENTS/////////////////////
//////////////////////////////////////////////

contract TokenEvents {

    //when a user locks tokens
    event TokenLock(
        address indexed user,
        uint value
    );

    //when a user unlocks tokens
    event TokenUnlock(
        address indexed user,
        uint value
    );

}

//////////////////////////////////////
//////////HXBLOCK CONTRACT////////
////////////////////////////////////
contract HxbLock is TokenEvents {

    using SafeMath for uint256;

    address public hxbAddress = 0x9BB6fd000109E24Eb38B0Deb806382fF9247E478;
    IERC20 hxbInterface = IERC20(hxbAddress);
    //lock setup
    uint internal daySeconds = 86400;// seconds in a day
    uint public total369Locked;
    uint public lockDayLength = 369;
    
    mapping (address => uint) public token369LockedBalances;//balance of HXB locked mapped by user
    
    bool private sync;

    mapping (address => Locked) public locked;

    struct Locked{
        uint256 lock369StartTimestamp;
    }
    
    //protects against potential reentrancy
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor() public {

    }

    ////////////////////////////////////////////////////////
    /////////////////PUBLIC FACING - HXB LOCK CONTROL//////////
    //////////////////////////////////////////////////////

    //lock HXB tokens to contract
    function LockTokens(uint amt)
        public
    {
        require(amt > 0, "zero input");
        require(hxbInterface.balanceOf(msg.sender) >= amt, "Error: insufficient balance");//ensure user has enough funds
        if(isLockFinished(msg.sender)){
            UnlockTokens();//unlocks all currently locked tokens if finished
        }
        token369LockedBalances[msg.sender] = token369LockedBalances[msg.sender].add(amt);
        total369Locked = total369Locked.add(amt);
        locked[msg.sender].lock369StartTimestamp = now;
        hxbInterface.transferFrom(msg.sender, address(this), amt);//make transfer
        emit TokenLock(msg.sender, amt);
    }
    
    //unlock HXB tokens from contract
    function UnlockTokens()
        public
        synchronized
    {
        uint amt = 0;
        require(token369LockedBalances[msg.sender] > 0,"Error: unsufficient locked balance");//ensure user has enough locked funds
        require(isLockFinished(msg.sender), "tokens cannot be unlocked yet, min 369 days");
        amt = token369LockedBalances[msg.sender];
        token369LockedBalances[msg.sender] = 0;
        locked[msg.sender].lock369StartTimestamp = 0;
        total369Locked = total369Locked.sub(amt);
        hxbInterface.transfer(msg.sender, amt);//make transfer
        emit TokenUnlock(msg.sender, amt);
    }
    
    ///////////////////////////////
    ////////VIEW ONLY//////////////
    ///////////////////////////////

    function isLockFinished(address _user)
        public
        view
        returns(bool)
    {
        if(locked[_user].lock369StartTimestamp == 0){
            return false;
        }
        else{
           return locked[_user].lock369StartTimestamp.add(lockDayLength.mul(daySeconds)) <= now;               
        }
    }
}

