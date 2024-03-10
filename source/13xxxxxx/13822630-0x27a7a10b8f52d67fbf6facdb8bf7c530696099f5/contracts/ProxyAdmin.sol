// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract ProxyAdmin is
    Initializable,
    ContextUpgradeable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    mapping(string => bytes32) public roleName;

    function initialize(
        address pauser,
        address creator,
        address withdrawer
    ) public initializer {
        roleName["PAUSER_ROLE"] = keccak256("PAUSER_ROLE");
        roleName["CREATOR_ROLE"] = keccak256("CREATOR_ROLE");
        roleName["WITHDRAWER_ROLE"] = keccak256("WITHDRAWER_ROLE");
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(roleName["PAUSER_ROLE"], pauser);
        _setupRole(roleName["CREATOR_ROLE"], creator);
        _setupRole(roleName["WITHDRAWER_ROLE"], withdrawer);
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

