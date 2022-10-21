pragma solidity ^0.5.7;

import "./SafeMath.sol";
import "./ILockupContract.sol";
import "./Managed.sol";

contract LockupContract is ILockupContract, Managed  {

    mapping (address => uint256) public lockedAmount;
    event Lock(address holderAddress, uint256 amount);
    event UnLock(address holderAddress, uint256 amount);

    constructor(address _management)
    public
    Managed(_management)
    {}

    function lock(
        address _address,
        uint256 _amount
    )
    public
    requirePermission(CAN_LOCK_COINS)
    {
        lockedAmount[_address] = lockedAmount[_address].add(_amount);
        emit Lock(_address, _amount);
    }

    function unlock(
        address _address,
        uint256 _amount
    )
    public
    requirePermission(CAN_LOCK_COINS)
    {
        require(
            lockedAmount[_address] >= _amount,
            ERROR_WRONG_AMOUNT
        );
        lockedAmount[_address] = lockedAmount[_address].sub(_amount);
        emit UnLock(_address, _amount);
    }

    function isTransferAllowed(
        address _address,
        uint256 _value,
        uint256 _holderBalance
    )
    public
    view
    returns (bool)
    {
        if (
            lockedAmount[_address] == 0 ||
        _holderBalance.sub(lockedAmount[_address]) >= _value
        ) {
            return true;
        }

        return false;
    }

    function allowedBalance(
        address _address,
        uint256 _holderBalance
    )
    public
    view
    returns (uint256)
    {
        if (lockedAmount[_address] == 0) {
            return _holderBalance;
        }
        return _holderBalance.sub(lockedAmount[_address]);
    }
}

