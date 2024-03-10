pragma solidity ^0.6.0;

import "./AccessControl.sol";
import "./Ownable.sol";

contract ManagerRole is AccessControl, Ownable {

    bytes32 public constant MANAGER_ADMIN_ROLE = keccak256("MANAGER_ADMIN_ROLE");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    bool private _finalized = false;
    event Finalized();

    modifier onlyManager() {
        require(hasRole(MANAGER_ROLE, msg.sender), "ManagerRole: caller does not have the Manager role");
        _;
    }

    constructor () public {
        _setRoleAdmin(MANAGER_ROLE, MANAGER_ADMIN_ROLE);
    }

    /**
     * @dev Create and ading new role.
     * @param role role account.
     * @param account account for adding to the role.
     */
    function addAdmin(bytes32 role, address account) public virtual onlyOwner returns (bool) {
        require(!_finalized, "ManagerRole: already finalized");

        _setupRole(role, account);
        return true;
    }

    /**
     * @dev Block adding admins.
     */
    function finalize() public virtual onlyOwner {
        require(!_finalized, "ManagerRole: already finalized");

        _finalized = true;
        emit Finalized();
    }
}
