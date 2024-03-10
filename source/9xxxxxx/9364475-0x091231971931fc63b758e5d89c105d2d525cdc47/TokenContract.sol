pragma solidity >=0.4.21 <0.6.0;

contract TokenContract {
    function balanceOf(address ownerAddress) public view returns (uint);
    function transfer(address to, uint tokens) public returns (bool success);
}
