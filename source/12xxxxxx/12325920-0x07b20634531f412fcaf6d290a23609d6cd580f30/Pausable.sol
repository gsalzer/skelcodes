pragma solidity = 0.5.16;

import "./Ownable.sol";

contract Pausable is Ownable {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;
    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "YouSwap:PAUSED");
        _;
    }

    modifier whenPaused() {
        require(_paused, "YouSwap:NOT_PAUSED");
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}
