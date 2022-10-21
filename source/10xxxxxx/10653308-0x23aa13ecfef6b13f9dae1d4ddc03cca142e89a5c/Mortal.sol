pragma solidity ^0.4.26;

import "./Owned.sol";

contract Mortal is Owned
{
    function destroy() public onlyOwner {
        selfdestruct(owner);
    }
}
