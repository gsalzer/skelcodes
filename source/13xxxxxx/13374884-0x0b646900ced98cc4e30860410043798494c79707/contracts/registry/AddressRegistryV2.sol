// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {Initializable, OwnableUpgradeSafe} from "contracts/proxy/Imports.sol";
import {IAddressRegistryV2} from "./IAddressRegistryV2.sol";

contract AddressRegistryV2 is
    Initializable,
    OwnableUpgradeSafe,
    IAddressRegistryV2
{
    /* ------------------------------- */
    /* impl-specific storage variables */
    /* ------------------------------- */
    /** @dev the same address as the proxy admin; used
     *  to protect init functions for upgrades */
    address private _proxyAdmin; // <-- deprecated in V2.
    bytes32[] internal _idList;
    mapping(bytes32 => address) internal _idToAddress;

    /* ------------------------------- */

    /**
     * @dev Since the proxy delegate calls to this "logic" contract, any
     * storage set by the logic contract's constructor during deploy is
     * disregarded and this function is needed to initialize the proxy
     * contract's storage according to this contract's layout.
     *
     * Since storage is not set yet, there is no simple way to protect
     * calling this function with owner modifiers.  Thus the OpenZeppelin
     * `initializer` modifier protects this function from being called
     * repeatedly.  It should be called during the deployment so that
     * it cannot be called by someone else later.
     *
     * NOTE: this function is copied from the V1 contract and has already
     * been called during V1 deployment.  It is included here for clarity.
     */
    function initialize(address adminAddress) external initializer {
        require(adminAddress != address(0), "INVALID_ADMIN");

        // initialize ancestor storage
        __Context_init_unchained();
        __Ownable_init_unchained();

        // initialize impl-specific storage
        // _setAdminAddress(adminAddress);  <-- deprecated in V2.
    }

    /**
     * @dev Dummy function to show how one would implement an init function
     * for future upgrades.  Note the `initializer` modifier can only be used
     * once in the entire contract, so we can't use it here.  Instead, we
     * protect the upgrade init with the `onlyProxyAdmin` modifier, which
     * checks `msg.sender` against the proxy admin slot defined in EIP-1967.
     * This will only allow the proxy admin to call this function during upgrades.
     */
    // solhint-disable-next-line no-empty-blocks
    function initializeUpgrade() external virtual onlyProxyAdmin {}

    function registerMultipleAddresses(
        bytes32[] calldata ids,
        address[] calldata addresses
    ) external override onlyOwner {
        require(ids.length == addresses.length, "Inputs have differing length");
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 id = ids[i];
            address address_ = addresses[i];
            registerAddress(id, address_);
        }
    }

    function deleteAddress(bytes32 id) external override onlyOwner {
        for (uint256 i = 0; i < _idList.length; i++) {
            if (_idList[i] == id) {
                // copy last element to slot i and shorten array
                _idList[i] = _idList[_idList.length - 1];
                _idList.pop();
                address address_ = _idToAddress[id];
                delete _idToAddress[id];
                emit AddressDeleted(id, address_);
                break;
            }
        }
    }

    function getIds() external view override returns (bytes32[] memory) {
        return _idList;
    }

    function chainlinkRegistryAddress()
        external
        view
        override
        returns (address)
    {
        return tvlManagerAddress();
    }

    function daiPoolAddress() external view override returns (address) {
        return getAddress("daiPool");
    }

    function usdcPoolAddress() external view override returns (address) {
        return getAddress("usdcPool");
    }

    function usdtPoolAddress() external view override returns (address) {
        return getAddress("usdtPool");
    }

    function mAptAddress() external view override returns (address) {
        return getAddress("mApt");
    }

    function lpAccountAddress() external view override returns (address) {
        return getAddress("lpAccount");
    }

    function lpSafeAddress() external view override returns (address) {
        return getAddress("lpSafe");
    }

    function adminSafeAddress() external view override returns (address) {
        return getAddress("adminSafe");
    }

    function emergencySafeAddress() external view override returns (address) {
        return getAddress("emergencySafe");
    }

    function oracleAdapterAddress() external view override returns (address) {
        return getAddress("oracleAdapter");
    }

    function registerAddress(bytes32 id, address address_)
        public
        override
        onlyOwner
    {
        require(address_ != address(0), "Invalid address");
        if (_idToAddress[id] == address(0)) {
            // id wasn't registered before, so add it to the list
            _idList.push(id);
        }
        _idToAddress[id] = address_;
        emit AddressRegistered(id, address_);
    }

    function tvlManagerAddress() public view override returns (address) {
        return getAddress("tvlManager");
    }

    function getAddress(bytes32 id) public view override returns (address) {
        address address_ = _idToAddress[id];
        require(address_ != address(0), "Missing address");
        return address_;
    }
}

