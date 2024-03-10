pragma solidity ^0.4.25;

import "./Ownalbe.sol";

contract Croupier is Ownable {
    address internal _croupier;

    event CroupiershipTransferred(address indexed previousCroupier, address indexed newCroupier);

    constructor () internal {
        _croupier = msg.sender;
        emit CroupiershipTransferred(address(0), _croupier);
    }

    /**
     * @return the address of the croupier.
     */
    function croupier() public view returns (address) {
        return _croupier;
    }

    /**
     * @dev Throws if called by any account other than the croupier.
     */
    modifier onlyCroupier() {
        require(isOwner() || isCroupier());
        _;
    }

    /**
     * @return true if `msg.sender` is the croupier of the contract.
     */
    function isCroupier() public view returns (bool) {
        return msg.sender == _croupier;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newCroupier.
     * @param newCroupier The address to transfer croupiership to.
     */
    function transferCroupiership(address newCroupier) public onlyOwner {
        _transferCroupiership(newCroupier);
    }

    /**
     * @dev Transfers control of the contract to a newCroupier.
     * @param newCroupier The address to transfer croupiership to.
     */
    function _transferCroupiership(address newCroupier) internal {
        require(newCroupier != address(0));
        emit CroupiershipTransferred(_croupier, newCroupier);
        _croupier = newCroupier;
    }
}

