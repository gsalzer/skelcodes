pragma solidity ^0.5.5;

import "./StandardToken.sol";
import "./MultiOwnable.sol";
/**
 * @title Lockable token
 */
contract LockableToken is StandardToken, MultiOwnable {
    bool public locked = true;

    /**
     * dev 락 = TRUE  이여도  거래 가능한 언락 계정
     */
    mapping(address => bool) public unlockAddrs;

    /**
     * dev - 계정마다 lockValue만큼 락이 걸린다.
     * dev - lockValue = 0 > limit이 없음
     */
    mapping(address => uint256) public lockValues;

    event Locked(bool locked, string note);
    event LockedTo(address indexed addr, bool locked, string note);
    event SetLockValue(address indexed addr, uint256 value, string note);

    constructor() public {
        unlockTo(msg.sender,  "");
    }

    modifier checkUnlock (address addr, uint256 value) {
        require(!locked || unlockAddrs[addr], "The account is currently locked.");
        require(balances[addr].sub(value) >= lockValues[addr], "Transferable limit exceeded. Check the status of the lock value.");
        _;
    }

    function lock(string memory note) public onlyOwner {
        locked = true;
        emit Locked(locked, note);
    }

    function unlock(string memory note) public onlyOwner {
        locked = false;
        emit Locked(locked, note);
    }

    function lockTo(address addr, string memory note) public onlyOwner {
        setLockValue(addr, balanceOf(addr), note);
        unlockAddrs[addr] = false;

        emit LockedTo(addr, true, note);
    }

    function unlockTo(address addr, string memory note) public onlyOwner {
        setLockValue(addr, 0, note);
        unlockAddrs[addr] = true;

        emit LockedTo(addr, false, note);
    }

    function setLockValue(address addr, uint256 value, string memory note) public onlyOwner {
        lockValues[addr] = value;
        if(value == 0){
            unlockAddrs[addr] = true;    
        }else{
            unlockAddrs[addr] = false;
        }

        emit SetLockValue(addr, value, note);
    }

    /**
     * dev 이체 가능 금액 체크
     */
    function getMyUnlockValue() public view returns (uint256) {
        address addr = msg.sender;
        if ((!locked || unlockAddrs[addr]) )
            return balances[addr].sub(lockValues[addr]);
        else
            return 0;
    }

    function transfer(address to, uint256 value) public checkUnlock(msg.sender, value) returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public checkUnlock(from, value) returns (bool) {
        return super.transferFrom(from, to, value);
    }
}
