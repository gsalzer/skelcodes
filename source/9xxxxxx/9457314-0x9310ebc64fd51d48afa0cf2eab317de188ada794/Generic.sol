pragma solidity ^0.6.1;
pragma experimental ABIEncoderV2;

contract Generic {
    
    struct RetVal {
        bool  boolValue;
        bytes bytesValue;
    }
    
    function generic(address dest, bytes memory data, uint value) payable public returns(bool, bytes memory){
        return dest.call.value(value)(data);
    }
    
    function simulate(address[] memory dests, bytes[] memory datum, uint[] memory value) payable public returns(RetVal[] memory retVal) {
        retVal = new RetVal[](dests.length);

        for(uint i = 0 ; i < dests.length ; i++) {
            (retVal[i].boolValue, retVal[i].bytesValue) = generic(dests[i], datum[i], value[i]);
        }
    }
}
