// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* DATA STRUCT IMPORTS */

import "./proxy/InitializableStore.sol";
import "./access/manager/ManagerRoleStore.sol";
import "./ERC20/ERC20Store.sol";
import "./extensions/pausable/PausableStore.sol";
import "./extensions/freezable/FreezableStore.sol";

struct XenoERC20Store {
    InitializableStore initializable;
    ManagerRoleStore managerRole;
    ERC20Store erc20;
    PausableStore pausable;
    FreezableStore freezable; // the slot taken by the struct of this is the last slotted item
}
