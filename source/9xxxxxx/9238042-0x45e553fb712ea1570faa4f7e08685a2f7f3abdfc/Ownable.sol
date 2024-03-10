pragma solidity 0.5.12;

import './ERC20Detailed.sol';
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is ERC20Detailed {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
  function initialize(address sender) public initializer {
    _owner = sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
     * @dev Returns the address of the current owner.
     */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
     * @dev Throws if called by any account other than the owner.
     */
  modifier onlyOwner() {
    require(isOwner(), 'Ownable: caller is not the owner');
    _;
  }

  /**
     * @dev Returns true if the caller is the current owner.
     */
  function isOwner() public view returns (bool) {
    return _msgSender() == _owner;
  }

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
  function transferOwnership(address newOwner) external onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  uint256[50] private ownableGap;
}

