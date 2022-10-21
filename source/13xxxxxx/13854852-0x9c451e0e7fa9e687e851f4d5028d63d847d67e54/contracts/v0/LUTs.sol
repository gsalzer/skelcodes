// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./libraries/LUTsLoader.sol";

abstract contract LUTs {
    /**
     * Contains a supply growth scale representing the curve
     * of the price per token function
     *
     * See `LUTsLoader` for actual details
     */
    uint256[] internal _supplyLUT;

    /**
     * Contains price per token for each element of the `_supplyLUT`
     * representing price per token growth function.
     *
     * See `LUTsLoader` for actual values.
     */
    uint256[] internal _priceLUT;

    /**
     * A pointer to a `_supplyLUT` segment corresponding to the current token
     * supply.
     *
     * Note that `nodeId` may be either determined on the fly by calling
     * `Calculator.adjustNodeId()` or stored onchain. The latter
     * reduces gas costs upon every purchase.
     */
    uint8 internal _nodeId;

    /**
     * Fills `_supplyLUT` with the values defined in the `LUTsLoader` library
     */
    function initSupplyLUT0() external {
        LUTsLoader.fillSupplyNodes0(_supplyLUT);
    }

    function initSupplyLUT1() external {
        LUTsLoader.fillSupplyNodes1(_supplyLUT);
    }

    function initSupplyLUT2() external {
        LUTsLoader.fillSupplyNodes2(_supplyLUT);
    }

    function initSupplyLUT3() external {
        LUTsLoader.fillSupplyNodes3(_supplyLUT);
    }

    /**
     * Fills `_priceLUT` with the values defined in the `LUTsLoader` library
     */
    function initPriceLUT0() external {
        LUTsLoader.fillPriceNodes0(_priceLUT);
    }

    function initPriceLUT1() external {
        LUTsLoader.fillPriceNodes1(_priceLUT);
    }

    function initPriceLUT2() external {
        LUTsLoader.fillPriceNodes2(_priceLUT);
    }

    function initPriceLUT3() external {
        LUTsLoader.fillPriceNodes3(_priceLUT);
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}

