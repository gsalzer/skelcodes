pragma solidity ^0.5.0;

contract PermissionsEnum {
    enum Permissions {
        CREATE_LOT,
        CREATE_SUB_LOT,
        UPDATE_LOT,
        TRANSFER_LOT_OWNERSHIP,
        ALLOCATE_SUPPLY
    }
}

