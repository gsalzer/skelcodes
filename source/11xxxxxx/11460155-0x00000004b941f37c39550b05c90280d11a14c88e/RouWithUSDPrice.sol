// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;

import "LibBaseAuth.sol";
import "LibIEtherUSDPrice.sol";
import "LibIVokenSale.sol";


contract WithUSDPrice is BaseAuth {
    uint256 private _resaleEtherUSDPrice;
    uint256 private _defaultEtherUSDPrice;
    uint256 private _defaultVokenUSDPrice;

    IEtherUSDPrice private _etherUSDPriceContract;
    IVokenSale private _vokenSaleContract;


    constructor ()
    {
        _resaleEtherUSDPrice = 350e6;
        _defaultEtherUSDPrice = 580e6;
        _defaultVokenUSDPrice = 0.5e6;
    }

    /**
     * @dev Set Ether USD Price Contract.
     */
    function setEtherUSDPriceContract(address etherUSDPriceContract_)
        external
        onlyAgent
    {
        _etherUSDPriceContract = IEtherUSDPrice(etherUSDPriceContract_);
    }

    /**
     * @dev Set Voken Sale Contract.
     */
    function setVokenSaleContract(address vokenSaleContract_)
        external
        onlyAgent
    {
        _vokenSaleContract = IVokenSale(vokenSaleContract_);
    }

    /**
     * @dev Set default USD price of ETH and VokenTB.
     */
    function setDefaultUSDPrice(
        uint256 resaleEtherUSDPrice_,
        uint256 defaultEtherUSDPrice_,
        uint256 defaultVokenUSDPrice_
    )
        external
        onlyAgent
    {
        _resaleEtherUSDPrice = resaleEtherUSDPrice_;
        _defaultEtherUSDPrice = defaultEtherUSDPrice_;
        _defaultVokenUSDPrice = defaultVokenUSDPrice_;
    }

    /**
     * @dev Returns the (resale) ETH price in USD, with 6 decimals.
     */
    function resaleEtherUSDPrice()
        internal
        view
        returns (uint256)
    {
        return _resaleEtherUSDPrice;
    }

    /**
     * @dev Returns the ETH price in USD, with 6 decimals.
     */
    function _etherUSDPrice()
        internal
        view
        returns (uint256)
    {
        if (_etherUSDPriceContract != IEtherUSDPrice(0)) {
            try _etherUSDPriceContract.etherUSDPrice() returns (uint256 value) {
                return value;
            }
            
            catch {
                return _defaultEtherUSDPrice; 
            }
        }

        return _defaultEtherUSDPrice;
    }

    /**
     * @dev Returns the Voken price in USD, with 6 decimals.
     */
    function vokenUSDPrice()
        internal
        view
        returns (uint256)
    {
        if (_vokenSaleContract != IVokenSale(0)) {
            try _vokenSaleContract.vokenUSDPrice() returns (uint256 value) {
                return value;
            }
            
            catch {
                return _defaultVokenUSDPrice;
            }
        }

        return _defaultVokenUSDPrice;
    }
}


