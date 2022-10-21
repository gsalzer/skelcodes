pragma solidity >=0.4.21 <0.7.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    /**
      * @dev The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() public {
        _owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: only owner can call");
        _;
    }

    /**
     * @dev Returns the owner of the token.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
        return true;
    }
}
