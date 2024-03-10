pragma solidity 0.5.2;

/**
 * @title   LockETH contract.
 *
 * @dev     Escrows ETH until `_endOfLockUp`. Calling `unlockETH()` after `_endOfLockUp` sends ETH
 *          to `_contractOwner`.
 */
contract LockETH {

    uint256 public _endOfLockUp;
    address payable public _contractOwner;

    constructor (uint256 endOfLockUp, address payable contractOwner) public payable {

        _endOfLockUp = endOfLockUp;
        _contractOwner = contractOwner;

    }

    /**
     * @dev Send ETH owned by this contract to `_contractOwner`. Can be called by anyone but
     *      requires `block.timestamp` > `endOfLockUp`.
     */
    function unlockETH() external {

        // Verify end of lock-up period.
        require(block.timestamp > _endOfLockUp, 'Cannot claim yet.');

        // Send ETH balance to `_contractOwner`.
        _contractOwner.transfer(address(this).balance);

    }

}
