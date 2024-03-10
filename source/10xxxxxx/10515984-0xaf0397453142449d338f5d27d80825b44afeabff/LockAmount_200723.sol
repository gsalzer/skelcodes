pragma solidity ^0.5.0;

import "./Ownable.sol";

contract LockAmount is Ownable {
    /**
     * @dev 락정보 정의 (시간, 락금액)
     */
    struct LockInfo {
        uint256 timestamp;
        uint256 lockedAmount;
    }
    
    /**
     * @dev 락정보
     */
    mapping (address => string) internal _accountLockTypes;
    mapping (string => LockInfo[]) internal _lockInfoTable;
    
    /**
     * @dev 이벤트
     */
    event SetAccountLockType(address account, string lockType);
    event AddLockInfo(string  lockType, uint256 timestamp, uint256 lockAmount);
    event RemoveLockInfo(string lockType, uint256 timestamp);
    event ClearLockInfo(string lockType);
    
    /**
     * @dev 락테이블에서 현재시간의 락잔액조회
     */
    function getLockedAmountOfLockTable(address account) public view returns (uint256) {
        string memory lockType = _accountLockTypes[account];
        if (bytes(lockType).length != 0) {
            // 락금액 검색
            LockInfo[] memory array = _lockInfoTable[lockType];
            for (uint256 i = 0; i < array.length; i++) {
                if (array[i].timestamp >= block.timestamp) {
                    return array[i].lockedAmount;
                }
            }
        }
        return 0;
    }
    
    function getblockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    
    /**
     * @dev ADMIN 락타입 설정
     */
    function _setAccountLockType(address account, string memory lockType) internal returns (bool) {
        _accountLockTypes[account] = lockType;
        emit SetAccountLockType(account, lockType);
        return true;
    }

    /**
     * @dev ADMIN 락타입 여러개 설정
     */
    function setAccountsLockType(address[] memory account, string memory lockType) onlyOwner public returns (bool) {
        for (uint256 i = 0; i < account.length ; i++) {
            _setAccountLockType(account[i], lockType);
        }
        return true;
    }
    
    /**
     * @dev 락타입
     */
    function getAddressLockType (address account) public view returns (string memory) {
        return _accountLockTypes[account];
    }
    
    /**
     * @dev ADMIN 락정보 추가
     */
    function _addLockInfo(string memory lockType, uint256 timestamp, uint256 lockAmount) internal returns (bool) {

        // 락정보 인덱스 검색
        uint256 index = 0;
        LockInfo[] storage array = _lockInfoTable[lockType];
        for (index = 0; index < array.length; index++) {
            if (array[index].timestamp < timestamp) continue;
            if (array[index].timestamp > timestamp) break;

            if (index - 1 < array.length && array[index - 1].lockedAmount < lockAmount) return false;          
            if (index + 1 < array.length && array[index + 1].lockedAmount > lockAmount) return false;


            array[index].lockedAmount = lockAmount;
     

            emit AddLockInfo(lockType, timestamp, lockAmount);
            return true;
        }

        if (index - 1 < array.length && array[index - 1].lockedAmount < lockAmount) return false;          
        if (index < array.length && array[index].lockedAmount > lockAmount) return false;

        array.length++;
        for (uint256 i = array.length - 1; i > index; i--) {
            array[i] = array[i - 1];
        }
        array[index] = LockInfo(timestamp, lockAmount);
        
        emit AddLockInfo(lockType, timestamp, lockAmount);
        return true;
    }

    /**
     * @dev ADMIN 락정보 여러개 추가
     */
    function addLockInfoes(string memory lockType, uint256[] memory timestamp, uint256[] memory lockAmount) onlyOwner public returns (bool) {
        require(timestamp.length != 0, "timestamp must be not empty");
        require(bytes(lockType).length != 0, "lockType must be not empty");
        for (uint256 i = 0; i < timestamp.length ; i++) {
            _addLockInfo(lockType, timestamp[i], lockAmount[i]);
        }
        return true;
    }

    /**
     * @dev ADMIN 락설정 및 락정보 추가
     */
    function addLockTypeWithLockInfo(address[] memory account, string memory lockType, uint256[] memory timestamp, uint256[] memory lockAmount) onlyOwner public returns (bool) {
        require(timestamp.length != 0, "timestamp must be not empty");
        require(account.length != 0, "account must be not empty");
        for (uint256 i = 0; i < account.length ; i++) {
            _setAccountLockType(account[i], lockType);
        }
        for (uint256 i = 0; i < timestamp.length ; i++) {
            _addLockInfo(lockType, timestamp[i], lockAmount[i]);
        }
        return true;
    }
    
    /**
     * @dev ADMIN 락정보 삭제
     */
    function removeLockInfo(string memory lockType, uint256 timestamp) onlyOwner public returns (bool) {
        require(bytes(lockType).length != 0, "lockType must be not empty");

        LockInfo[] storage array = _lockInfoTable[lockType];
        if (array.length == 0) return false;

        // 락정보 인덱스 검색
        uint256 index = 2 ** 256 - 1;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i].timestamp == timestamp) {
                index = i;
                break;
            }
        }
        
        if (index == 2 ** 256 - 1) return false;

        // 락정보 삭제
        for (uint256 j = index; j < array.length - 1; j++) {
            array[j] = array[j + 1];
        }
        delete array[array.length - 1];
        array.length--;
        
        emit RemoveLockInfo(lockType, timestamp);
        return true;
    }

    /**
     * @dev ADMIN 락정보 클리어
     */
    function clearLockInfo(string memory lockType) onlyOwner public returns (bool) {
        require(bytes(lockType).length != 0, "lockType must be not empty");

        LockInfo[] storage array = _lockInfoTable[lockType];
        if (array.length == 0) return false;
        
        // 락정보 클리어
        for (uint256 i = 0; i < array.length; i++) {
            delete array[i];
        }
        array.length = 0;
        
        emit ClearLockInfo(lockType);
        return true;
    }

    /**
     * @dev 락타입별 정보 개수 조회
     */
    function getLockInfoCount(string memory lockType) public view returns (uint256) {
        return _lockInfoTable[lockType].length;
    }

    /**
     * @dev 락타입별 인덱스로 시간 조회
     */
    function getLockInfoAtIndex(string memory lockType, uint256 index) public view returns (uint256, uint256) {
        return (_lockInfoTable[lockType][index].timestamp, _lockInfoTable[lockType][index].lockedAmount);
    }
    
    /**
     * @dev 락타입별 시간, 락금액 조회
     */
    function getLockInfo(string memory lockType) public view returns (uint256[] memory, uint256[] memory) {
        uint256 index = 0;
        
        LockInfo[] memory array = _lockInfoTable[lockType];
        uint256[] memory timestamps = new uint256[](array.length);
        uint256[] memory lockedAmounts = new uint256[](array.length);
        
        for (index = 0; index < array.length; index++) {
            timestamps[index] = array[index].timestamp;
            lockedAmounts[index] = array[index].lockedAmount;
        }
        
        return (timestamps, lockedAmounts);
    }
}

