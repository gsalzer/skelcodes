pragma solidity ^0.5.8;

contract Ownable
{
    string constant public ERROR_NO_HAVE_PERMISSION = 'Reason: No have permission.';
    string constant public ERROR_IS_STOPPED         = 'Reason: Is stopped.';
    string constant public ERROR_ADDRESS_NOT_VALID  = 'Reason: Address is not valid.';

    bool private stopped;
    address private _owner;
    address[] public _allowed;

    event Stopped();
    event Started();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Allowed(address indexed _address);
    event RemoveAllowed(address indexed _address);

    constructor () internal
    {
        stopped = false;
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address)
    {
        return _owner;
    }

    modifier onlyOwner()
    {
        require(isOwner(), ERROR_NO_HAVE_PERMISSION);
        _;
    }

    modifier onlyAllowed()
    {
        require(isAllowed() || isOwner(), ERROR_NO_HAVE_PERMISSION);
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

    function isAllowed() public view returns (bool)
    {
        uint256 length = _allowed.length;

        for(uint256 i=0; i<length; i++)
        {
            if(_allowed[i] == msg.sender)
            {
                return true;
            }
        }

        return false;
    }

    function transferOwnership(address newOwner) external onlyOwner
    {
        _transferOwnership(newOwner);
    }

    function allow(address _target) external onlyOwner returns (bool)
    {
        uint256 length = _allowed.length;

        for(uint256 i=0; i<length; i++)
        {
            if(_allowed[i] == _target)
            {
                return true;
            }
        }

        _allowed.push(_target);

        return true;
    }

    function removeAllowed(address _target) external onlyOwner returns (bool)
    {
        uint256 length = _allowed.length;

        for(uint256 i=0; i<length; i++)
        {
            if(_allowed[i] == _target)
            {
                if(i < length - 1)
                {
                    _allowed[i] = _allowed[length-1];
                    delete _allowed[length-1];
                }
                else
                {
                    delete _allowed[i];
                }

                _allowed.length--;

                return true;
            }
        }

        return true;
    }

    function isStopped() public view returns (bool)
    {
        if(isOwner() || isAllowed())
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
