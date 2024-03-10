pragma solidity 0.5.8;

import "./ERC20Whitelisted.sol";

contract PermissionService is ERC20Whitelisted {

    mapping (address => bool) public mintablePermission;
    mapping (address => bool) public addWhitelistPermission;
    mapping (address => bool) public removeWhitelistPermission;
    mapping (address => bool) public replaceRegulatorServicePermission;
    mapping (address => bool) public editRightsPermission;
    mapping (address => bool) public recoveryTokensPermission;
    mapping (address => bool) public attributesPermission;
    mapping (address => bool) internal _isLocked;
    mapping (address => uint) internal _lockup;
    mapping (address => bool) internal _isAdded;

    address[] internal addressesWithPermissions;

    modifier onlyUnlocked() {
        require(_isLocked[msg.sender] == false && _lockup[msg.sender] < block.timestamp);
        _;
    }

    modifier onlyReplaceRegulatorServicePermission() {
        require(replaceRegulatorServicePermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyEditRightsPermission() {
        require(editRightsPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyRemoveWhitelistPermission() {
        require(removeWhitelistPermission[msg.sender] || recoveryTokensPermission[msg.sender] || isOwner());
        _;
    }

    modifier onlyAddWhitelistPermission() {
        require(addWhitelistPermission[msg.sender] || recoveryTokensPermission[msg.sender] || isOwner());
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

    function lockAddressFor(address account, uint time) public onlyEditRightsPermission {
        require(time > block.timestamp);
        _lockup[account] = time;
    }

    function lockAddress(address account) public onlyEditRightsPermission {
        _isLocked[account] = true;
    }

    function unlockAddress(address account) public onlyEditRightsPermission {
        _isLocked[account] = false;
        _lockup[account] = 0;
    }

    function isLocked(address account) public view returns(bool) {
        return _isLocked[account] || _lockup[account] >= block.timestamp;
    }

    function getTimeLockFor(address account) public view returns(uint) {
        return _lockup[account];
    }

    function addMintablePermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        mintablePermission[_address] = true;
    }

    function addAddWhitelistPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        addWhitelistPermission[_address] = true;
    }

    function addRemoveWhitelistPermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        removeWhitelistPermission[_address] = true;
    }

    function addReplaceRegulatorServicePermission(address _address) public onlyEditRightsPermission {
        if(_isAdded[_address] == false) {
            addressesWithPermissions.push(_address);
            _isAdded[_address] = true;
        }
        replaceRegulatorServicePermission[_address] = true;
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

    function removeAddWhitelistPermission(address _address) public onlyEditRightsPermission {
        addWhitelistPermission[_address] = false;
    }

    function removeRemoveWhitelistPermission(address _address) public onlyEditRightsPermission {
        removeWhitelistPermission[_address] = false;
    }

    function removeReplaceRegulatorServicePermission(address _address) public onlyEditRightsPermission {
        replaceRegulatorServicePermission[_address] = false;
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
