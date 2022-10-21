pragma solidity 0.5.3;

import "./Arbitrator.sol";

contract Arbitrable {

    function rule(uint _dispute, uint _ruling) public;

    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);
}
