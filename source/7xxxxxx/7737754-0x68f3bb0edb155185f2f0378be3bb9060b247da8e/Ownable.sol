pragma solidity ^0.5.8;

contract Ownable
{
    string constant public ERROR_NO_HAVE_PERMISSION = 'Reason: No have permission.';
    string constant public ERROR_IS_STOPPED         = 'Reason: Is stopped.';
    string constant public ERROR_ADDRESS_NOT_VALID  = 'Reason: Address is not valid.';

    bool private stopped;
    address private _owner;
    address private _master;

    event Stopped();
    event Started();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MasterRoleTransferred(address indexed previousMaster, address indexed newMaster);

    constructor () internal
    {
        stopped = false;
        _owner = msg.sender;
        _master = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit MasterRoleTransferred(address(0), _master);
    }

    function owner() public view returns (address)
    {
        return _owner;
    }

    function master() public view returns (address)
    {
        return _master;
    }

    modifier onlyOwner()
    {
        require(isOwner(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyMaster()
    {
        require(isMaster() || isOwner(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyWhenNotStopped()
    {
        require(!isStopped(), ERROR_IS_STOPPED);
        _;
    }

    function isOwner() public view returns (bool)
    {
        return msg.sender == _owner;
    }

    function isMaster() public view returns (bool)
    {
        return msg.sender == _master;
    }

    function transferOwnership(address newOwner) external onlyOwner
    {
        _transferOwnership(newOwner);
    }

    function transferMasterRole(address newMaster) external onlyOwner
    {
        _transferMasterRole(newMaster);
    }

    function isStopped() public view returns (bool)
    {
        if(isOwner() || isMaster())
        {
            return false;
        }
        else
        {
            return stopped;
        }
    }

    function stop() public onlyOwner
    {
        _stop();
    }

    function start() public onlyOwner
    {
        _start();
    }

    function _transferOwnership(address newOwner) internal
    {
        require(newOwner != address(0), ERROR_ADDRESS_NOT_VALID);
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _transferMasterRole(address newMaster) internal
    {
        require(newMaster != address(0), ERROR_ADDRESS_NOT_VALID);
        emit MasterRoleTransferred(_master, newMaster);
        _master = newMaster;
    }

    function _stop() internal
    {
        emit Stopped();
        stopped = true;
    }

    function _start() internal
    {
        emit Started();
        stopped = false;
    }
}
