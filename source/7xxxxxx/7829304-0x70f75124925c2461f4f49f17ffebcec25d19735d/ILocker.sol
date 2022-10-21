pragma solidity >=0.4.25 <0.6.0;

contract ILocker {
    function lockedBalanceOf(address holder_) public view returns (uint256);
}
