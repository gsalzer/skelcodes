pragma solidity 0.5.0;

import "./AdminNOwnable.sol";
import "./SafeMath.sol";

contract TokenLock is AdminNOwnable {

    using SafeMath for uint256;

    bool public transferEnabled = false; // indicates that token is transferable or not
    bool public noTokenLocked = false; // indicates all token is released or not

    struct TokenLockInfo { // token of `amount` cannot be moved before `time`
        uint256 amount; // locked amount
        uint256 time; // unix timestamp
    }

    struct TokenLockState {
        uint256 latestReleaseTime;
        uint256[] tokenLockAmount;
        uint256[] tokenLockReleasetime;
    }

    mapping(address => TokenLockState) lockingStates;
    event AddTokenLock(address indexed to, uint256 time, uint256 amount);

    function unlockAllTokens() public onlyOwner {
        noTokenLocked = true;
    }

    function enableTransfer(bool _enable) public onlyOwner {
        transferEnabled = _enable;
    }
   
    function getLockingStates(address _addr) public view returns (uint256, uint256[] memory, uint256[] memory) { 
        TokenLockState storage lockState = lockingStates[_addr]; 
        return (lockState.latestReleaseTime, lockState.tokenLockAmount, lockState.tokenLockReleasetime);
    }

    function getNow() public view returns (uint256) {  
        return now;
    }
   
     function getMinLockedAmount(address _addr) public view returns (uint256 locked) {
        uint256 i;
        uint256 a;
        uint256 t = 0;
        uint256 lockSum = 0;

        // if the address has no limitations just return 0
        TokenLockState storage lockState = lockingStates[_addr];
        if(lockState.latestReleaseTime < now){
            return 0;
        } 

        for(i=0; i<lockState.tokenLockAmount.length; i++ ){
            a = lockState.tokenLockAmount[i];
            if(i < lockState.tokenLockReleasetime.length) t = lockState.tokenLockReleasetime[i]; 

            if (t > now) {
                lockSum = lockSum.add(a);
            }
        }

        return lockSum;
    }

   
    function addTokenLock(address _addr, uint256 _value, uint256 _release_time) public onlyOwnerOrAdmin {
        require(_addr != address(0));
        require(_value > 0);
        require(_release_time > now);

        TokenLockState storage lockState = lockingStates[_addr]; // assigns a pointer. change the member value will update struct itself.
        if (_release_time > lockState.latestReleaseTime) {
            lockState.latestReleaseTime = _release_time;
        }
        lockState.tokenLockAmount.push(_value);
        lockState.tokenLockReleasetime.push(_release_time); 

        emit AddTokenLock(_addr, _release_time, _value);
    }

}
