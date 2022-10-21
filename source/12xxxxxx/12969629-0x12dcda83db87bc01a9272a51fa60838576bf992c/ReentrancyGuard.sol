// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// We can't use the default implementation of OpenZeppelin's Ownable because it uses a constructor which doesn't work with Proxy contracts

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 0;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    // Constructor doesn't work with Upgradable Proxy
    /*constructor() {
        _status = _NOT_ENTERED;
    }*/

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
