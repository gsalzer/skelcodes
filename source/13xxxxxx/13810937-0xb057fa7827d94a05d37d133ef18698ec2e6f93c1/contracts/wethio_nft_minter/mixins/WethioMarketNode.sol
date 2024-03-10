// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Wethio market contract.
 */
abstract contract WethioMarketNode is Initializable {
    using AddressUpgradeable for address;

    address private market;

    /**
     * @dev Called once after the initial deployment to set the Wethio treasury address.
     */
    function _initializeWethioMarketNode(address _market) internal initializer {
        require(
            _market.isContract(),
            "Wethio MarketNode: Address is not a contract"
        );
        market = _market;
    }

    /**
     * @notice Returns the address of the Wethio market.
     */
    function getWethioMarket() public view returns (address) {
        return market;
    }

    /**
     * @notice Updates the address of the Wethio treasury.
     */
    function _updateWethioMarket(address _market) internal {
        require(
            _market.isContract(),
            "Wethio MarketNode: Address is not a contract"
        );
        market = _market;
    }

    uint256[1000] private __gap;
}

