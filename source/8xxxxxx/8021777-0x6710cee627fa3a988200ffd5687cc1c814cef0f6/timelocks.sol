pragma solidity ^0.5.7;

import "./erc20.sol";

contract Timelocks is ERC20{

    uint public lockedBalance;

    struct Locker {
        uint amount;
        uint locktime;
    }

    mapping(address => Locker[]) timeLocks;

    /**
    * @dev function that lock tokens held by contract. Tokens can be unlocked and send to user after fime pass
    * @param lockTimestamp timestamp after whih coins can be unlocked
    * @param amount amount of tokens to lock
    * @param user address of uset that cn unlock and posess tokens
    */
	function _lock(uint lockTimestamp, uint amount, address user) internal{
        uint current = _balances[address(this)];
        require(amount <= current.sub(lockedBalance), "Lock: Not enough tokens");
        lockedBalance = lockedBalance.add(amount);
        timeLocks[user].push(Locker(amount, lockTimestamp));
    }

    /**
     * @dev Function to unlock timelocked tokens
     * If block.timestap passed tokens are sent to owner and lock is removed from database
     */
    function unlock() external
    {
        require(timeLocks[msg.sender].length > 0, "Unlock: No locks!");
        Locker[] storage l = timeLocks[msg.sender];
        for (uint i = 0; i < l.length; i++)
        {
            if (l[i].locktime < block.timestamp) {
                uint amount = l[i].amount;
                require(amount <= lockedBalance && amount <= _balances[address(this)], "Unlock: Not enough coins on contract!");
                lockedBalance = lockedBalance.sub(amount);
                _transfer(address(this), msg.sender, amount);
                for (uint j = i; j < l.length - 1; j++)
                {
                    l[j] = l[j + 1];
                }
                l.length--;
                i--;
            }
        }
    }

    /**
     * @dev Function to check how many locks are on caller account
     * We need it because (for now) contract can not retrurn array of structs
     * @return number of timelocked locks
     */
    function locks() external view returns(uint)
    {
        return _locks(msg.sender);
    }

    /**
     * @dev Function to check timelocks of any user
     * @param user addres of user
     * @return nuber of locks
     */
    function locks(address user) external view returns(uint) {
        return _locks(user);
    }

    function _locks(address user) internal view returns(uint){
        return timeLocks[user].length;
    }

    /**
     * @dev Function to check given timeLock
     * @param num number of timeLock
     * @return amount locked
     * @return timestamp after whih coins can be unlocked
     */
    function showLock(uint num) external view returns(uint, uint)
    {
        return _showLock(msg.sender, num);
    }

    /**
     * @dev Function to show timeLock of any user
     * @param user address of user
     * @param num number of lock
     * @return amount locked
     * @return timestamp after whih can be unlocked
     */
    function showLock(address user, uint num) external view returns(uint, uint) {
        return _showLock(user, num);
    }

    function _showLock(address user, uint num) internal view returns(uint, uint) {
        require(timeLocks[user].length > 0, "ShowLock: No locks!");
        require(num < timeLocks[user].length, "ShowLock: Index over number of locks.");
        Locker[] storage l = timeLocks[user];
        return (l[num].amount, l[num].locktime);
    }
}

