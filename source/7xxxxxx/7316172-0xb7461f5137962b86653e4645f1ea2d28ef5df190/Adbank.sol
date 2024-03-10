pragma solidity 0.5.0;

contract Adbank {

    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint _amount) public returns (bool ok);
}

