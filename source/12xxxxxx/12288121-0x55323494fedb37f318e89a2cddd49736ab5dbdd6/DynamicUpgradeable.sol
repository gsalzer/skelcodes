// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./DynamicUpgradeableStorage.sol";

/*****************************************************************************************************/
/**                                             WARNING                                             **/
/**                              THIS CONTRACT IS AN UPGRADEABLE FACET!                             **/
/**  ---------------------------------------------------------------------------------------------  **/
/**  Do NOT place ANY storage/state variables directly in this contract! If you wish to make        **/
/**  make changes to the state variables used by this contract, do so in its defined Storage        **/
/**  contract that this contract inherits from                                                      **/
/**                                                                                                 **/
/**  Visit https://docs.openzeppelin.com/upgrades/2.6/proxies#upgrading-via-the-proxy-pattern for   **/
/**  more information.                                                                              **/
/*****************************************************************************************************/
/**
 * @notice This contract is used define the DynamicUpgradeable contracts logic.
 *
 */
contract DynamicUpgradeable is DynamicUpgradeableStorage {
    /* Modifiers */

    /**
     * @notice It checks if the proxy's implementation cache is invalidated and should be updated.
     * @dev Any external, non-view function should use this modifier.
     * @dev This modifier should be the very FIRST modifier for functions.
     */
    modifier updateImpIfNeeded() {
        if (_cacheInvalidated()) {
            _updateImplementationStored();
        }
        _;
    }

    /* External Functions */

    /**
     * @notice It updates a proxy's cached implementation address.
     * @notice It must only be called by the LogicVersionsRegistry for non strict DynamicProxy
     */
    function upgradeProxyTo(address newImplementation) public {
        require(msg.sender == address(logicRegistry), "MUST_BE_LOGIC_REGISTRY");
        implementationStored = newImplementation;
        _implementationBlockUpdated = block.number;
    }

    /* Internal Functions **/

    /**
     * @notice Returns the current implementation used by the proxy to delegate a call to.
     * @return address of the current implementation
     */
    function _implementation() internal view virtual returns (address) {
        if (_cacheInvalidated()) {
            (, , address currentLogic) =
                logicRegistry.getLogicVersion(logicName);
            return currentLogic;
        }
        return implementationStored;
    }

    /**
     * @notice Updates the current implementation logic address for the stored logic name.
     * @dev It uses the LogicVersionsRegistry contract to get the logic address or the cached address if valid.
     * @dev It caches the current logic address for the proxy to reduce gas on subsequent calls within the same block.
     */
    function _updateImplementationStored() public {
        (, , address currentLogic) = logicRegistry.getLogicVersion(logicName);

        if (implementationStored != currentLogic) {
            implementationStored = currentLogic;
        }
        _implementationBlockUpdated = block.number;
    }

    /**
     * @notice It checks if the current cached address implementation is marked as invalidated.
     * @notice It is marked invalidated if the proxy is strict dynamic and last update was >= 50 blocks ago.
     * @return bool True if the cached implementation address is invalid.
     */
    function _cacheInvalidated() internal view returns (bool) {
        return strictDynamic && _implementationBlockUpdated + 1 <= block.number;
    }
}

