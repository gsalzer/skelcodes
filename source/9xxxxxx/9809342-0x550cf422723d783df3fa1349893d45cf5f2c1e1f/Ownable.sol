pragma solidity ^0.5.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    address public newOwner;

    // There can be multiple controller (designated operator) accounts.
    address[] internal controllers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public {
        owner = msg.sender;
    }
   
    /**
    * @dev Throws if called by any account that's not a controller.
    */
    modifier onlyController() {
        require(isController(msg.sender), "only Controller");
        _;
    }

    modifier onlyOwnerOrController() {
        require(msg.sender == owner || isController(msg.sender), "only Owner Or Controller");
        _;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner, "sender address must be the owner's address");
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a new owner.
    * @param _newOwner The address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(address(0) != _newOwner, "new owner address must not be the owner's address");
        newOwner = _newOwner;
    }

    /**
    * @dev Allows the new owner to confirm that they are taking control of the contract.
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender address must not be the new owner's address");
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

    function isController(address _controller) internal view returns(bool) {
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return true;
            }
        }
        return false;
    }

    function getControllers() public onlyOwner view returns(address[] memory) {
        return controllers;
    }

    /**
    * @dev Allows a new controllers to be added
    * @param _controller The address of the controller account.
    */
    function addController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        require(_controller != owner, "controller address must not be the owner's address");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                return;
            }
        }
        controllers.push(_controller);
    }

    /**
    * @dev Remove a controller from the list
    * @param _controller The address of the controller account.
    */
    function removeController(address _controller) public onlyOwner {
        require(address(0) != _controller, "controller address must not be 0");
        for (uint8 index = 0; index < controllers.length; index++) {
            if (controllers[index] == _controller) {
                delete controllers[index];
            }
        }
    }
}
