pragma solidity ^0.4.23;

import './1.TempoToken.sol';
import './Ownable.sol';

contract AuthRepo is Ownable {
    constructor () public {}


    event Authorized();

    function authorizeContract() public returns (bool) {
        emit Authorized();
        return true;
    }

}

