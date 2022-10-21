pragma solidity 0.5.7;

contract Simple
{
    address public owner;

    constructor (address ownerAddress) public
    {
        owner = ownerAddress;
    }
}
