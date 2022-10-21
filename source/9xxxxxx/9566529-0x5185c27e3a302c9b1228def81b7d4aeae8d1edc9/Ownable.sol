pragma solidity ^0.5.16;


contract Ownable {
    address payable public owner;
    address payable public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /// @notice Transfer ownership from `owner` to `newOwner`
    /// @param _newOwner The new contract owner
    function transferOwnership(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            newOwner = _newOwner;
        }
        return;
    }

    /// @notice accept ownership of the contract
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

