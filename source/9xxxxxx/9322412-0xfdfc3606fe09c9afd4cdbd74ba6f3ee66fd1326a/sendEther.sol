/**
 *Submitted for verification at Etherscan.io on 2020-01-15
*/

pragma solidity ^0.6.0;
    
contract sendEther {
    uint256 public a;
    uint256 public b;

    function transfer(uint256 _a) public payable {
        a = _a;
    }
    
    function transfer(uint256 _a, uint256 _b) public payable {
        a = _a;
        b = _b;
    }
    
    function showMe(uint256 _a) public view returns (uint256, uint256[] memory) {
        if(_a > 0) {
            uint256[] memory test = new uint[](3);
            test[0] = 456;
            test[1] = 654;
            test[2] = 888;
            return(123, test);
        }
    }
}
