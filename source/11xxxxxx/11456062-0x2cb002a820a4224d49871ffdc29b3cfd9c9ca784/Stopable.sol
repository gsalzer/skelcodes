pragma solidity ^0.5.0;

import "./Ownable.sol";
/**
 * @title Stoppable
 * @dev Change status public value for contract operation.
 */
contract Stoppable is Ownable{
    bool public stopped = false;
    
    modifier enabled {
        require (!stopped);
        _;
    }
    /**
        * @dev Run only owner. For vaalue change
    */
    function stop() external onlyOwner { 
        stopped = true; 
    }
    /**
        * @dev Run only owner. For vaalue change
    */
    function start() external onlyOwner {
        stopped = false;
    }    
}

