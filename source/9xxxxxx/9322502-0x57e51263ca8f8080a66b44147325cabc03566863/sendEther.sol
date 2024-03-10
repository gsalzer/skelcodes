/**
 *Submitted for verification at Etherscan.io on 2020-01-15
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;
    
contract sendEther {
    uint256 public a;
    uint256 public b;
    
    struct thisIsAStruct {
        uint256 NumberOne;
        string NumberString;
    }
    
    thisIsAStruct public myStruct;
    
    constructor() public {
        myStruct.NumberOne = 1;
        myStruct.NumberString = "Test String";
    }
    

    function transfer(uint256 _a) public payable {
        a = _a;
    }
    
    function transfer(uint256 _a, uint256 _b) public payable {
        a = _a;
        b = _b;
    }
    
    function showMe() public view returns (uint256, string[] memory) {
        string[] memory test = new string[](3);
        test[0] = "456";
        test[1] = "654";
        test[2] = "8888";
        return(123, test);
    }
    
    function showMeWithInput(uint256 _a) public view returns (uint256, string[] memory) {
        if(_a > 0) {
            string[] memory test = new string[](3);
            test[0] = "456";
            test[1] = "654";
            test[2] = "8888";
            return(123, test);
        }
    }
    
    function showStructWithInput(uint256 _a) public view returns (thisIsAStruct memory) {
        return myStruct;
    }
}
