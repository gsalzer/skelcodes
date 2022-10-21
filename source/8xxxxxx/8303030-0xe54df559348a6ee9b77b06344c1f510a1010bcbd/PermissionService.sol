pragma solidity 0.5.8;

import "./ERC20.sol";

contract PermissionService is ERC20 {

    mapping (address => bool) public mintablePermission;
    mapping (address => bool) public editRightsPermission;
    mapping (address => bool) public recoveryTokensPermission;
    mapping (address => bool) public attributesPermission;
    mapping (address => bool) public burnPermission;
    mapping (address => bool) internal _isAdded;

    address[] internal addressesWithPermissions;

    modifier onlyEditRightsPermission() {
        require(editRightsPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyBurnPermission() {
        require(burnPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyMintablePermission() {
        require(mintablePermission[msg.sender] || recoveryTokensPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyRecoveryTokensPermission() {
        require(recoveryTokensPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyAttributesPermission() {
        require(attributesPermission[msg.sender] || isOwner());
        _;
    }

    function addMintablePermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        mintablePermission[_address] = true;
    }

    function addBurnPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        burnPermission[_address] = true;
    }

    function addEditRightsPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        editRightsPermission[_address] = true;
    }

    function addRecoveryTokensPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        recoveryTokensPermission[_address] = true;
    }

    function addAttributesPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        attributesPermission[_address] = true;
    }

    function removeMintablePermission(address _address) public onlyEditRightsPermission {
        mintablePermission[_address] = false;
    }

    function removeBurnPermission(address _address) public onlyEditRightsPermission {
        burnPermission[_address] = false;
    }

    function removeEditRightsPermission(address _address) public onlyEditRightsPermission {
        editRightsPermission[_address] = false;
    }

    function removeRecoveryTokensPermission(address _address) public onlyEditRightsPermission {
        recoveryTokensPermission[_address] = false;
    }

    function removeAttributesPermission(address _address) public onlyEditRightsPermission {
        attributesPermission[_address] = false;
    }

    function getAddressesWithPermissions() public view returns(address[] memory) {
        return addressesWithPermissions;
    }


}
