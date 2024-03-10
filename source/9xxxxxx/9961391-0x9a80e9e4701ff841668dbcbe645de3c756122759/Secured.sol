pragma solidity 0.5.0;

import "./IHasAdmin.sol";

contract Secured is IHasAdmin {

    uint256 private _count;
    mapping(address => bool) private _admins;

    constructor() public {
        _count = 1;
        _admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(_admins[msg.sender]);
        _;
    }

    function isAdmin(address accountAddress) public view returns (bool)
    {
        return _admins[accountAddress];
    }

    function addAdmin(address accountAddress) public onlyAdmin {
        require(!_admins[accountAddress]);
        _count++;
        _admins[accountAddress] = true;
    }

    function removeAdmin(address accountAddress) public onlyAdmin {
        require(_count > 1);
        require(_admins[accountAddress]);
        _count--;
        delete _admins[accountAddress];
    }

    function transferAdmin(address fromAddress, address toAddress) public onlyAdmin {
        require(_admins[fromAddress]);
        require(!_admins[toAddress]);
        delete _admins[fromAddress];
        _admins[toAddress] = true;
    }
}
