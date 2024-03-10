pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

contract Test123 {
    struct a {
        string b;
    }
    
    a Something;
    
    function adjustSomething(string memory _a) public {
        Something.b = _a;
    }
    
    function viewSomething() public view returns (a memory) {
        return Something;
    }
    
}
