pragma solidity ^0.5.0;

/**
* @dev Ownable authentication.
*/
contract Ownable {

    /**
    * @dev Owner account.
    */
    address private _owner;

    /**
    * @dev Init owner as the contract creator.
    */
    constructor() public {
        _owner = msg.sender;
    }

    /**
    * @dev Owner authentication.
    */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: authentication failed");
        _;
    }

    /**
    * @dev Get current owner.
    */
    function getOwner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Transfer owner.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(_owner != newOwner, "Ownable: transfer ownership new owner and old owner are the same");
        address oldOwner = _owner; _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
    * @dev Event transfer owner.
    */
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
}
