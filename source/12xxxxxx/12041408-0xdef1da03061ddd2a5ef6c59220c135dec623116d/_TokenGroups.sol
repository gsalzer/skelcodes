// SPDX-License-Identifier: LicenseRef-Blockwell-Smart-License
pragma solidity ^0.6.10;

import "./_Pausable.sol";
import "./_Groups.sol";

/**
 * @dev User groups for Prime Token.
 *
 * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
 */
contract TokenGroups is Pausable {
    uint8 public constant ADMIN = 1;
    uint8 public constant ATTORNEY = 2;
    uint8 public constant BUNDLER = 3;
    uint8 public constant WHITELIST = 4;
    uint8 public constant FROZEN = 5;
    uint8 public constant BW_ADMIN = 6;
    uint8 public constant SWAPPER = 7;
    uint8 public constant DELEGATE = 8;

    using Groups for Groups.GroupMap;

    Groups.GroupMap groups;

    event AddedToGroup(uint8 indexed groupId, address indexed account);
    event RemovedFromGroup(uint8 indexed groupId, address indexed account);

    event BwAddedAttorney(address indexed account);
    event BwRemovedAttorney(address indexed account);
    event BwRemovedAdmin(address indexed account);

    modifier onlyAdminOrAttorney() {
        require(isAdmin(msg.sender) || isAttorney(msg.sender));
        _;
    }

    // ATTORNEY

    // dapp https://app.blockwell.ai/0tezcv
    function _addAttorney(address account) internal {
        _add(ATTORNEY, account);
    }

    function addAttorney(address account) public whenNotPaused onlyAdminOrAttorney {
        _add(ATTORNEY, account);
    }

    /**
     * @dev Allows BW admins to add an attorney to the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwAddAttorney(address account) public onlyBwAdmin {
        _add(ATTORNEY, account);
        emit BwAddedAttorney(account);
    }

    // dapp https://app.blockwell.ai/7qtyz4
    function removeAttorney(address account) public whenNotPaused onlyAdminOrAttorney {
        _remove(ATTORNEY, account);
    }

    /**
     * @dev Allows BW admins to remove an attorney from the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwRemoveAttorney(address account) public onlyBwAdmin {
        _remove(ATTORNEY, account);
        emit BwRemovedAttorney(account);
    }

    function isAttorney(address account) public view returns (bool) {
        return _contains(ATTORNEY, account);
    }

    // ADMIN

    function _addAdmin(address account) internal {
        _add(ADMIN, account);
    }

    // dapp https://app.blockwell.ai/mtzj2e
    function addAdmin(address account) public whenNotPaused onlyAdminOrAttorney {
        _addAdmin(account);
    }

    // dapp https://app.blockwell.ai/40pc9e
    function removeAdmin(address account) public whenNotPaused onlyAdminOrAttorney {
        _remove(ADMIN, account);
    }

    /**
     * @dev Allows BW admins to remove an admin from the contract in emergency cases.
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function bwRemoveAdmin(address account) public onlyBwAdmin {
        _remove(ADMIN, account);
        emit BwRemovedAdmin(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _contains(ADMIN, account);
    }

    // BUNDLER

    // dapp https://app.blockwell.ai/i8sxu0
    function addBundler(address account) public onlyAdminOrAttorney {
        _add(BUNDLER, account);
    }

    // dapp https://app.blockwell.ai/z72enu
    function removeBundler(address account) public onlyAdminOrAttorney {
        _remove(BUNDLER, account);
    }

    function isBundler(address account) public view returns (bool) {
        return _contains(BUNDLER, account);
    }

    modifier onlyBundler() {
        require(isBundler(msg.sender));
        _;
    }

    // SWAPPER

    // dapp https://app.blockwell.ai/amcwpf
    function addSwapper(address account) public onlyAdminOrAttorney {
        _addSwapper(account);
    }

    function _addSwapper(address account) internal {
        _add(SWAPPER, account);
    }

    function removeSwapper(address account) public onlyAdminOrAttorney {
        _remove(SWAPPER, account);
    }

    function isSwapper(address account) public view returns (bool) {
        return _contains(SWAPPER, account);
    }

    modifier onlySwapper() {
        require(isSwapper(msg.sender));
        _;
    }

    // WHITELIST

    // dapp https://app.blockwell.ai/y4c4n2
    function addToWhitelist(address account) public onlyAdminOrAttorney {
        _add(WHITELIST, account);
    }

    // dapp https://app.blockwell.ai/n4408a
    function removeFromWhitelist(address account) public onlyAdminOrAttorney {
        _remove(WHITELIST, account);
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _contains(WHITELIST, account);
    }

    // BW_ADMIN

    function _addBwAdmin(address account) internal {
        _add(BW_ADMIN, account);
    }

    function addBwAdmin(address account) public onlyBwAdmin {
        _addBwAdmin(account);
    }

    function renounceBwAdmin() public {
        _remove(BW_ADMIN, msg.sender);
    }

    function isBwAdmin(address account) public view returns (bool) {
        return _contains(BW_ADMIN, account);
    }

    modifier onlyBwAdmin() {
        require(isBwAdmin(msg.sender));
        _;
    }

    // FROZEN

    function _freeze(address account) internal {
        _add(FROZEN, account);
    }

    // dapp https://app.blockwell.ai/0ldfpw
    function freeze(address account) public onlyAdminOrAttorney {
        _freeze(account);
    }

    function _unfreeze(address account) internal {
        _remove(FROZEN, account);
    }

    // dapp https://app.blockwell.ai/qcwqg6
    function unfreeze(address account) public onlyAdminOrAttorney {
        _unfreeze(account);
    }

    /**
     * @dev Freeze multiple accounts with a single transaction.
     *
     * dapp https://app.blockwell.ai/t0rw3c
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiFreeze(address[] calldata account) public onlyAdminOrAttorney {
        require(account.length > 0);

        for (uint256 i = 0; i < account.length; i++) {
            _freeze(account[i]);
        }
    }

    /**
     * @dev Unfreeze multiple accounts with a single transaction.
     *
     * dapp https://app.blockwell.ai/7updhm
     *
     * Blockwell Exclusive (Intellectual Property that lives on-chain via Smart License)
     */
    function multiUnfreeze(address[] calldata account) public onlyAdminOrAttorney {
        require(account.length > 0);

        for (uint256 i = 0; i < account.length; i++) {
            _unfreeze(account[i]);
        }
    }

    function isFrozen(address account) public view returns (bool) {
        return _contains(FROZEN, account);
    }

    modifier isNotFrozen() {
        require(!isFrozen(msg.sender));
        _;
    }

    // DELEGATE

    // dapp https://app.blockwell.ai/cpyysz
    function addDelegate(address account) public onlyAdminOrAttorney {
        _add(DELEGATE, account);
    }

    // dapp https://app.blockwell.ai/a0j2al
    function removeDelegate(address account) public onlyAdminOrAttorney {
        _remove(DELEGATE, account);
    }

    function isDelegate(address account) public view returns (bool) {
        return _contains(DELEGATE, account);
    }

    // Internal functions

    function _add(uint8 groupId, address account) internal {
        groups.add(groupId, account);
        emit AddedToGroup(groupId, account);
    }

    function _remove(uint8 groupId, address account) internal {
        groups.remove(groupId, account);
        emit RemovedFromGroup(groupId, account);
    }

    function _contains(uint8 groupId, address account) internal view returns (bool) {
        return groups.contains(groupId, account);
    }
}

