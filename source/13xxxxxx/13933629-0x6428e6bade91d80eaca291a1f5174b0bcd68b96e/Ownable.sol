// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Context {
    /**
     * @return Address of the transaction message sender {msg.sender}
     * Returns the msg.sender
     */
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @param tokenOwner address of the token owner
     * Transfers ownership to tokenOwner
     */
    constructor(address tokenOwner) {
        _transferOwnership(tokenOwner);
    }

    /**
     * @return Address of the owner of the contract
     * Returns the owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Modifier that checks if the msg.sender is the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address 0x0
     */
    function renounceOwnership() public onlyOwner returns(bool) {
        _transferOwnership(address(0));
        return true;
    }
    
    /**
     * @return Boolean value true if flow was successful
     * Only owner can call the function
     * Releases ownership to address newOwner
     */
    function transferOwnership(address newOwner) public onlyOwner returns(bool){
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
        return true;
    }

    /**
     * Sets newOwner as the owner and emits the OwnershipTransferred event
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
