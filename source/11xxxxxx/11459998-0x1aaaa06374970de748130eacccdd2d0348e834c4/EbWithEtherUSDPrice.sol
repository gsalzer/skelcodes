// SPDX-License-Identifier: MIT
pragma solidity =0.7.5;


import "LibBaseAuth.sol";
import "LibIEtherUSDPrice.sol";


contract WithEtherUSDPrice is BaseAuth {
    uint256 private _defaultEtherUSDPrice;

    IEtherUSDPrice private _etherUSDPriceContract;

    constructor ()
    {
        _defaultEtherUSDPrice = 580e6;
    }

    /**
     * @dev Set Ether USD Price Contract.
     */
    function setEtherUSDPriceContract(address etherUSDPriceContract)
        external
        onlyAgent
    {
        _etherUSDPriceContract = IEtherUSDPrice(etherUSDPriceContract);
    }

    /**
     * @dev Set default USD price of ETH and VokenTB.
     */
    function setDefaultUSDPrice(
        uint256 defaultEtherUSDPrice
    )
        external
        onlyAgent
    {
        _defaultEtherUSDPrice = defaultEtherUSDPrice;
    }

    /**
     * @dev Returns the ETH price in USD, with 6 decimals.
     */
    function etherUSDPrice()
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
}

