pragma solidity >=0.7.0;

contract SingleOwnerDelegateCall
{
    address public implementation;
    address public owner;

    modifier onlyUninitialized() {
        require(owner == address(0), "ABQDAO/only-uninitialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ABQDAO/only-owner");
        _;
    }

    function setOwner(address _owner)
        external
        onlyUninitialized()
    {
        owner = _owner;
        emit OwnerChanged(_owner);
    }

    event OwnerChanged(address newOwner);
    function changeOwner(address _newOwner)
        external
        onlyOwner()
    {
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    event DelegateCallPerformed(address target, bytes data);
    function performDelegateCall(address _target, bytes calldata _data) 
        external
        onlyOwner()
    {
        (bool success, ) = _target.delegatecall(_data);
        require(success, "ABQDAO/could-not-delegate-call");
        emit DelegateCallPerformed(_target, _data);
    }
}
