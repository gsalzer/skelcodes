pragma solidity ^0.5.0;

import "./ERC20Ownable.sol";

contract ERC20Pausable is ERC20Ownable{

    event Pause();
    event Unpause();

    bool private _paused;

    /**
     * @dev The Pausable constructor sets the default `paused` is false
     */
    constructor () internal {
        _paused = false;
        emit Unpause();
    }

    /**
        * @dev Total number of tokens in existence
        */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        _paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        _paused = false;
        emit Unpause();
    }


}

