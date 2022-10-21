// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {

    address private _owner;

    mapping (address => bool) private _managers;

	event ManagerRemoved(address indexed _manager);

	event ManagerAdded(address indexed _manager);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the managers.
     */
    modifier onlyManager() {
        require(isManager(), "Ownable: caller is not the manager");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isManager() public view returns (bool) {
        return _managers[msg.sender];
    }

	/**
	 * @dev Allows the owner to add manager
	 * @param _manager The address to add managers permissions to.
	 */
	function addManager(address _manager) public onlyOwner {
		require(_manager != address(0), "Invalid new manager address");
		emit ManagerAdded(_manager);
		_managers[_manager] = true;
	}

	/**
	 * @dev Allows the owner to remove manager.
	 * @param _manager The address to remove manager permissions to.
	 */
	function removeManager(address _manager) public onlyOwner {
		require(_manager != address(0), "Invalid new manager address");
		emit ManagerRemoved(_manager);
		delete _managers[_manager];
	}
}
