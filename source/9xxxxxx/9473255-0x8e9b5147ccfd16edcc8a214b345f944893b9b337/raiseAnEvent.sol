/**
 *Submitted for verification at Etherscan.io on 2020-01-09
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract raiseAnEvent {
    
    event raiseMeAnEvent(structDataType SDT);
    
    struct structDataType {
        string someInformationHere;
        uint256 someNumberHere;
    }
    
    constructor() public { }
    
    function callAndRaiseEvent(string memory _a, uint256 _b) public {
        structDataType memory tmp;
        tmp.someInformationHere = _a;
        tmp.someNumberHere = _b;
        
        emit raiseMeAnEvent(tmp);
    }
    
}
