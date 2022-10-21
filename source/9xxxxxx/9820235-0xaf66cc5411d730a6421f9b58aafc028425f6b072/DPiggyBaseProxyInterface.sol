pragma solidity ^0.6.4;

/**
 * @title DPiggyBaseProxyInterface
 * @dev DPiggyBaseProxy interface with external functions.
 */
interface DPiggyBaseProxyInterface {
    function setImplementation(address newImplementation, bytes calldata data) external payable;
    function setAdmin(address newAdmin) external;
}
