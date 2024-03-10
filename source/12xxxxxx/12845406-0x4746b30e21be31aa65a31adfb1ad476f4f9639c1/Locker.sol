// SPDX-License-Identifier: MIT
// Platinum Software Dev Team
// Locker  Beta  version.

pragma solidity ^0.8.4;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./LockerTypes.sol";

contract Locker is LockerTypes {
    using SafeERC20 for IERC20;

    string  constant public name = "Lock & Registry v0.0.3";


    /**
     * @dev Then more records in VestingRecord array then more gas will spend
     * in  `lockTokens` method  and in every getter call_getAvailableAmountByLockIndex.
     * So in some case it can revert After test we decide use yhis value. But it
     * is not up limit and you can try more
     */
    uint256 constant public MAX_VESTING_RECORDS_PER_LOCK  = 21;
    /**
     * @dev Then more records in _beneficiaries then more gas will spend
     * in  `lockTokens` method. After test we decide use yhis value. But it
     * is not up limit and you can try more
     */    
    uint256 constant public MAX_BENEFICIARIES_PER_LOCK    = 160;
    uint256 constant public MAX_LOCkS_PER_BENEFICIARY    = 1000;

    /**
     * @dev Then more TOTAL_IN_PERCENT then more precision.
     * but be attention with _beneficiariesShares array
     * accordingly this value
     */
    uint256 constant public TOTAL_IN_PERCENT = 1e13;
    LockStorageRecord[] lockerStorage;

    //map from users(investors)  to locked shares
    mapping(address => RegistryShare[])  public registry;

    //map from lockIndex to beneficiaries list
    mapping(uint256 => address[]) beneficiariesInLock;

    
    event NewLock(address indexed erc20, address indexed who, uint256 lockedAmount, uint256 lockId);
    
    /**
     * @dev Any who have token balance > 0 can lock  it here.
     *
     * Emits a NewLock event.
     *
     * Requirements:
     *
     * - `_ERC20` token contract address for lock.
     * - `_amount` amount of tokens to be locked.
     * - `_unlockedFrom` array of unlock dates in unixtime format.
     * - `_unlockAmount` array of unlock amounts.
     * - `_beneficiaries` array of address for beneficiaries.
     * - `_beneficiariesShares` array of beneficiaries shares, in % but 
     * - scaled on TOTAL_IN_PERCENT/100. So 20% = 2000 if TOTAL_IN_PERCENT=10000, 0.1% = 10 and etc.
     * Caller must approve _ERC20 tokens to this contract address before lock
     */
    function lockTokens(
        address _ERC20, 
        uint256 _amount, 
        uint256[] memory _unlockedFrom, 
        uint256[] memory _unlockAmount,
        address[] memory _beneficiaries,
        uint256[] memory _beneficiariesShares

    )
        external 

    {
        require(_amount > 0, "Cant lock 0 amount");
        require(IERC20(_ERC20).allowance(msg.sender, address(this)) >= _amount, "Please approve first");
        require(_getArraySum(_unlockAmount) == _amount, "Sum vesting records must be equal lock amount");
        require(_unlockedFrom.length == _unlockAmount.length, "Length of periods and amounts arrays must be equal");
        require(_beneficiaries.length == _beneficiariesShares.length, "Length of beneficiaries and shares arrays must be equal");
        require(_getArraySum(_beneficiariesShares) == TOTAL_IN_PERCENT, "Sum of shares array must be equal to 100%");
        require(_beneficiaries.length < MAX_BENEFICIARIES_PER_LOCK,   "MAX_BENEFICIARIES_PER_LOCK LIMIT");
        require(_unlockedFrom.length  < MAX_VESTING_RECORDS_PER_LOCK, "MAX_VESTING_RECORDS_PER_LOCK LIMIT");

        //Lets prepare vestings array
        VestingRecord[] memory v = new VestingRecord[](_unlockedFrom.length);
        for (uint256 i = 0; i < _unlockedFrom.length; i ++ ) {
                v[i].unlockTime = _unlockedFrom[i];
                v[i].amountUnlock = _unlockAmount[i]; 
        }
        
        //Save lock info in storage
        LockStorageRecord storage lock = lockerStorage.push();
        lock.ltype = LockType.ERC20;
        lock.token = _ERC20;
        lock.amount = _amount;


        //Copying of type struct LockerTypes.VestingRecord memory[] memory 
        //to storage not yet supported.
        //so we need this cycle
        for (uint256 i = 0; i < _unlockedFrom.length; i ++ ) {
            lock.vestings.push(v[i]);    
        }

        //Lets save _beneficiaries for this lock
        for (uint256 i = 0; i < _beneficiaries.length; i ++ ) {
            require(_beneficiaries[i] != address(0), 'Cant add zero address');
            require(_beneficiaries[i] != address(this), 'Bad idea');
            RegistryShare[] storage shares = registry[_beneficiaries[i]];
            require(
                shares.length <= MAX_LOCkS_PER_BENEFICIARY, 
                'MAX_LOCkS_PER_BENEFICIARY LIMIT'
            );
            shares.push(RegistryShare({
                lockIndex: lockerStorage.length - 1,
                sharePercent: _beneficiariesShares[i],
                claimedAmount: 0
            }));
            //Save beneficaries in one map for use in child conatrcts
            beneficiariesInLock[lockerStorage.length - 1].push(_beneficiaries[i]);
        }

        
        IERC20 token = IERC20(_ERC20);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit NewLock(_ERC20, msg.sender, _amount, lockerStorage.length - 1);

    }

    /**
     * @dev Any _beneficiaries can claim their tokens after vesting lock time is expired.
     *
     * Requirements:
     *
     * - `_lockIndex` array index, number of lock record in  storage. For one project lock case = 0
     * - `_desiredAmount` amount of tokens to be unlocked. Only after vesting lock time is expired
     * - If now date less then vesting lock time tx will be revert
     */
    function claimTokens(uint256 _lockIndex, uint256 _desiredAmount) external {
        //Lets get our lockRecord by index
        require(_lockIndex < lockerStorage.length, "Lock record not saved yet");
        require(_desiredAmount > 0, "Cant claim zero");
        LockStorageRecord memory lock = lockerStorage[_lockIndex];
        (uint256 percentShares, uint256 wasClaimed) = 
            _getUserSharePercentAndClaimedAmount(msg.sender, _lockIndex);
        uint256 availableAmount =
            _getAvailableAmountByLockIndex(_lockIndex)
            * percentShares / TOTAL_IN_PERCENT
            - wasClaimed;

        require(_desiredAmount <= availableAmount, "Insufficient for now");
        availableAmount = _desiredAmount;

        //update claimed amount
        _decreaseAvailableAmount(msg.sender, _lockIndex, availableAmount);

        //send tokens
        IERC20 token = IERC20(lock.token);
        token.safeTransfer(msg.sender, availableAmount);
    }

    

    /**
     * @dev Returns array of shares for user (beneficiary).
     * See LockerTypes.RegistryShare description.
     * In case of one project this will only one record
     * 
     * Requirements:
     *
     * - `_user` beneficiary address
     */
    function getUserShares(address _user) external view returns (RegistryShare[] memory) {
        return _getUsersShares(_user);
    }


    /**
     * @dev Returns tuple (totalBalance, available balance).
     * totalBalance - amount of all user shares minus already claimed
     * available - user balance that available for NOW, minus already claimed
     * -
     * Requirements:
     *
     * - `_user` beneficiary address
     * - `_lockIndex` array index, number of lock record in  storage. For one project lock case = 0
     */
    function getUserBalances(address _user, uint256 _lockIndex) external view returns (uint256, uint256) {
        return _getUserBalances(_user, _lockIndex);
    }

    /**
     * @dev Returns LockStorageRecord data struture.See LockerTypes.LockStorageRecord description.
     * -
     * Requirements:
     *
     * - `_index` array index, number of lock record in  storage. For one project lock case = 0
     */
    function getLockRecordByIndex(uint256 _index) external view returns (LockStorageRecord memory){
        return _getLockRecordByIndex(_index);
    }

    
    /**
     * @dev Returns LockStorage Record count, for iteration from app.
     * 
     */
    function getLockCount() external view returns (uint256) {
        return lockerStorage.length;
    }



    /**
     * @dev Just helper for array summ.
     * 
     */
    function getArraySum(uint256[] memory _array) external pure returns (uint256) {
        return _getArraySum(_array);
    }

    ////////////////////////////////////////////////////////////
    /////////// Internals           ////////////////////////////
    ////////////////////////////////////////////////////////////
    function _decreaseAvailableAmount(address user, uint256 _lockIndex, uint256 _amount) internal {
        RegistryShare[] storage shares = registry[user];
        for (uint256 i = 0; i < shares.length; i ++ ) {
            if  (shares[i].lockIndex == _lockIndex) {
                //It does not matter what record will update
                // with same _lockIndex. but only one!!!!
                shares[i].claimedAmount += _amount;
                break;
            }
        }

    }

    function _getArraySum(uint256[] memory _array) internal pure returns (uint256) {
        uint256 res = 0;
        for (uint256 i = 0; i < _array.length; i++) {
            res += _array[i];           
        }
        return res;
    }

    function _getAvailableAmountByLockIndex(uint256 _lockIndex) 
        internal 
        view 
        virtual
        returns(uint256)
    {
        VestingRecord[] memory v = lockerStorage[_lockIndex].vestings;
        uint256 res = 0;
        for (uint256 i = 0; i < v.length; i ++ ) {
            if  (v[i].unlockTime <= block.timestamp && !v[i].isNFT) {
                res += v[i].amountUnlock;
            }
        }
        return res;
    }


    function _getUserSharePercentAndClaimedAmount(address _user, uint256 _lockIndex) 
        internal 
        view 
        returns(uint256 percent, uint256 claimed)
    {
        RegistryShare[] memory shares = registry[_user];
        for (uint256 i = 0; i < shares.length; i ++ ) {
            if  (shares[i].lockIndex == _lockIndex) {
                //We do this cycle because one address can exist
                //more then once in one lock
                percent += shares[i].sharePercent;
                claimed += shares[i].claimedAmount;
            }
        }
        return (percent, claimed);
    }

    function _getUsersShares(address _user) internal view returns (RegistryShare[] memory) {
        return registry[_user];
    }

    function _getUserBalances(address _user, uint256 _lockIndex) internal view returns (uint256, uint256) {

        (uint256 percentShares, uint256 wasClaimed) =
            _getUserSharePercentAndClaimedAmount(_user, _lockIndex);

        uint256 totalBalance =
        lockerStorage[_lockIndex].amount
        * percentShares / TOTAL_IN_PERCENT
        - wasClaimed;

        uint256 available =
        _getAvailableAmountByLockIndex(_lockIndex)
        * percentShares / TOTAL_IN_PERCENT
        - wasClaimed;

        return (totalBalance, available);
     }


    function _getVestingsByLockIndex(uint256 _index) internal view returns (VestingRecord[] memory) {
        VestingRecord[] memory v = _getLockRecordByIndex(_index).vestings;
        return v;

    }

    function _getLockRecordByIndex(uint256 _index) internal view returns (LockStorageRecord memory){
        return lockerStorage[_index];
    }

}
