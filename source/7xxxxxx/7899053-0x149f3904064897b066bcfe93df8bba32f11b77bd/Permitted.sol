pragma solidity ^0.5.7;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./Constants.sol";
import "./PermissionsManagement.sol";

contract Permitted is Constants, Ownable {

    using SafeMath for uint256;

    PermissionsManagement public permissionsManagement;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    constructor(address _permissionsManagementContract) public {
        permissionsManagement = PermissionsManagement(
            _permissionsManagementContract
        );
    }

    function setPermissionsManagementContract(
        address _permissionsManagementContract
    )
        public
        onlyOwner
    {
        require(
            address(0) != _permissionsManagementContract,
            ERROR_ACCESS_DENIED
        );

        permissionsManagement = PermissionsManagement(
            _permissionsManagementContract
        );
    }

    function hasPermission(
        address _subject,
        uint256 _permissionBit
    )
        internal
        view
        returns (bool)
    {
        return permissionsManagement.permissions(_subject, _permissionBit);
    }

}


