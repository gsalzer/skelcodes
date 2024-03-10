pragma solidity ^0.5.7;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./IManaged.sol";
import "./Constants.sol";
import "./Management.sol";

contract Managed is IManaged, Constants, Ownable {

    using SafeMath for uint256;

    Management public management;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier canCallOnlyRegisteredContract(uint256 _key) {
        require(
            msg.sender == management.contractRegistry(_key),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    modifier requireContractExistsInRegistry(uint256 _key) {
        require(
            management.contractRegistry(_key) != address(0),
            ERROR_NO_CONTRACT
        );
        _;
    }

    constructor(address _managementAddress) public {
        management = Management(_managementAddress);
    }

    function setManagementContract(address _management) public onlyOwner {
        require(address(0) != _management, ERROR_ACCESS_DENIED);

        management = Management(_management);
    }

    function hasPermission(
        address _subject,
        uint256 _permissionBit
    )
    internal
    view
    returns (bool)
    {
        return management.permissions(_subject, _permissionBit);
    }

}

