pragma solidity 0.4.25;


contract OldManagerMock {
    mapping (address => uint256) public released;

    function release(address investor, uint256 amount) public {
    	released[investor] += amount;
    }
}
