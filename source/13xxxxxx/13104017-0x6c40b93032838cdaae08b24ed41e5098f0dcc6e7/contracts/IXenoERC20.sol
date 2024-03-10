// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* INTERFACE INHERITANCE IMPORTS */

import "./access/manager/interfaces/ManagerRoleInterface.sol";

import "./ERC20/interfaces/IERC20.sol";
import "./ERC20/interfaces/IERC20Metadata.sol";
import "./ERC20/interfaces/ERC20AllowanceInterface.sol";
import "./ERC20/interfaces/IERC20Burnable.sol";

import "./extensions/freezable/interfaces/FreezableInterface.sol";
import "./extensions/pausable/interfaces/PausableInterface.sol";
import "./extensions/recoverable/interfaces/RecoverableInterface.sol";

/**
 * @dev Interface for XenoERC20
 */
interface IXenoERC20 is
    ManagerRoleInterface,
    IERC20,
    IERC20Metadata,
    ERC20AllowanceInterface,
    IERC20Burnable,
    FreezableInterface,
    PausableInterface,
    RecoverableInterface
{ }
