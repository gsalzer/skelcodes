pragma solidity ^0.5.0;

import "./OrganizationInterface.sol";
import "./PermissionsEnum.sol";


/**
 * @title Organization
 * Organization contract to create new organization, add/delete Devices,
 * create new Lot
 */
contract Organization is OrganizationInterface, PermissionsEnum {

    address public lotFactory;

    mapping(address => bool) public adminDevices;

    mapping(address => bool) public permittedDevices;

    bool public isActive;

    event DeviceAdded (
        address device
    );

    event DeviceRemoved (
        address device
    );

    event AdminDeviceAdded (
        address device
    );

    event AdminDeviceRemoved (
        address device
    );

    event LotFactoryChanged (
        address oldFactory,
        address newFactory
    );

    modifier onlyOwnerAccess() {
        require(isAdminDevice(msg.sender), "Only admin device accesible");
        _;
    }

    modifier onlyPermittedAccess() {
        require(isPermittedDevice(msg.sender), "Only permitted device accesible");
        _;
    }

    constructor(
        address _lotFactory,
        address _organizationOwner,
        bool _isActive
    )
    public {
        lotFactory = _lotFactory;

        // Set all the roles to false initially
        isActive = _isActive;

        // make admin the owner device
        _permitAdminDevice(_organizationOwner);
    }
    
    /**
     * @dev Returns the organization info
     */
    function organizationInfo()
    public
    view
    returns (bool status) {
        status = isActive;
    }

    /**
     * @dev Check if device is able to add or remove permitted devices.
     * @param _device The address to device check access.
     */
    function isAdminDevice(address _device)
    public
    view
    returns (bool deviceAdmin)
    {
        return adminDevices[_device];
    }

    /**
     * @dev Check if device is Permitted to perform Lot related operations.
     * @param _device The address to device check access.
     */
    function isPermittedDevice(address _device)
    public
    view
    returns (bool devicePermitted)
    {
        return (permittedDevices[_device] || adminDevices[_device]);
    }

    /**
    * @dev Update lot factory address
    */
    function setLotFactory(address _lotFactory)
    public
    onlyOwnerAccess
    {
        address oldFactory = lotFactory;
        lotFactory = _lotFactory;

        // Emit we updated lot factory
        emit LotFactoryChanged(oldFactory, _lotFactory);
    }

    /**
     * @dev Allows the new _device to access organization.
     * @param _deviceAddress The address of new device which needs access to organization.
     */
    function permitDevice(address _deviceAddress)
    public
    onlyOwnerAccess
    returns (bool devicePermitted)
    {
        return _permitDevice(_deviceAddress);
    }

    function removeDevice(address _deviceAddress)
    public
    onlyOwnerAccess
    returns (bool devicePermitted)
    {
        return _removeDevice(_deviceAddress);
    }

    function _permitDevice(address _deviceAddress)
    private
    returns (bool devicePermitted)
    {
        //validation to check already exist in the list
        permittedDevices[_deviceAddress] = true;

        emit DeviceAdded(_deviceAddress);
        return true;
    }

    function _removeDevice(address _deviceAddress)
    private

    returns (bool devicePermitted)
    {
        permittedDevices[_deviceAddress] = false;

        emit DeviceRemoved(_deviceAddress);
        return true;
    }

    function permitAdminDevice(address _deviceAddress)
    public
    onlyOwnerAccess
    returns (bool deviceAdmin)
    {
        return _permitAdminDevice(_deviceAddress);
    }

    function removeAdminDevice(address _deviceAddress)
    public
    onlyOwnerAccess
    returns (bool deviceAdmin)
    {
        return _removeAdminDevice(_deviceAddress);
    }

    function _permitAdminDevice(address _deviceAddress)
    private
    returns (bool deviceAdmin)
    {
        //validation to check already exist in the list
        adminDevices[_deviceAddress] = true;
        permittedDevices[_deviceAddress] = true;

        emit AdminDeviceAdded(_deviceAddress);
        return true;
    }

    function _removeAdminDevice(address _deviceAddress)
    private
    returns (bool deviceAdmin)
    {
        adminDevices[_deviceAddress] = false;
        permittedDevices[_deviceAddress] = false;

        emit AdminDeviceRemoved(_deviceAddress);
        return true;
    }
    

    function hasPermissions(address permittee, uint256 permission)
    public
    view
    returns (bool)
    {
        if (permittee == address(this)) return true;

        if (permission == uint256(Permissions.CREATE_LOT)) return isPermittedDevice(permittee);
        if (permission == uint256(Permissions.CREATE_SUB_LOT)) return isPermittedDevice(permittee);
        if (permission == uint256(Permissions.UPDATE_LOT)) return isPermittedDevice(permittee);
        if (permission == uint256(Permissions.TRANSFER_LOT_OWNERSHIP)) return isPermittedDevice(permittee);
        if (permission == uint256(Permissions.ALLOCATE_SUPPLY)) return permittee == address(lotFactory);

        return false;
    }
}

