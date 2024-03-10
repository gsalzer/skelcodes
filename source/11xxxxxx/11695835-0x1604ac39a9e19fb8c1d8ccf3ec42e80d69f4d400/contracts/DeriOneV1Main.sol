// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./DeriOneV1HegicV888.sol";
import "./DeriOneV1OpynV1.sol";

/// @author tai
/// @title A contract for getting the cheapest options price
/// @notice For now, this contract gets the cheapest ETH/WETH put options price from Opyn V1 and Hegic V888
/// @dev explicitly state the data location for all variables of struct, array or mapping types (including function parameters)
/// @dev adjust visibility of variables. they should be all private by default i guess
/// @dev optimize gas consumption
contract DeriOneV1Main is DeriOneV1HegicV888, DeriOneV1OpynV1 {
    enum Protocol {HegicV888, OpynV1}
    struct TheCheapestETHPutOption {
        Protocol protocol;
        address oTokenAddress;
        address paymentTokenAddress;
        uint256 expiry;
        uint256 optionSizeInWEI;
        uint256 premiumInWEI;
        uint256 strikeInUSD;
    }

    // the cheapest ETH put option across options protocols
    TheCheapestETHPutOption private _theCheapestETHPutOption;

    event TheCheapestETHPutOptionGot(string protocolName);

    constructor(
        address _hegicETHOptionV888Address,
        address _hegicETHPoolV888Address,
        address _opynExchangeV1Address,
        address _opynOptionsFactoryV1Address,
        address _uniswapFactoryV1Address
    )
        public
        DeriOneV1HegicV888(_hegicETHOptionV888Address, _hegicETHPoolV888Address)
        DeriOneV1OpynV1(
            _opynExchangeV1Address,
            _opynOptionsFactoryV1Address,
            _uniswapFactoryV1Address
        )
    {}

    function theCheapestETHPutOption()
        public
        view
        returns (TheCheapestETHPutOption memory)
    {
        return _theCheapestETHPutOption;
    }

    /// @dev we could make another function that gets some options instead of only one
    /// @dev we could take fixed values for expiry and strike.
    /// @dev make this function into a view function somehow in the next version
    /// @param _minExpiry minimum expiration date in seconds from now
    /// @param _minStrikeInUSD minimum strike price in USD with 8 decimals
    /// @param _maxStrikeInUSD maximum strike price in USD with 8 decimals
    /// @param _optionSizeInWEI option size in WEI
    function getTheCheapestETHPutOption(
        uint256 _minExpiry,
        // uint256 _maxExpiry,
        uint256 _minStrikeInUSD,
        uint256 _maxStrikeInUSD,
        uint256 _optionSizeInWEI
    ) public returns (TheCheapestETHPutOption memory) {
        // require expiry. check if it is agter the latest block time
        // expiry needs to be seconds from now in hegic and timestamp in opyn v1
        // but we don't use the expiry for the opyn for now. so it's seconds now
        getTheCheapestETHPutOptionInHegicV888(
            _minExpiry,
            _optionSizeInWEI,
            _minStrikeInUSD
        );
        require(
            hasEnoughETHLiquidityInHegicV888(_optionSizeInWEI) == true,
            "your size is too big for liquidity in the Hegic V888"
        );
        getTheCheapestETHPutOptionInOpynV1(
            // _minExpiry,
            // _maxExpiry,
            _minStrikeInUSD,
            _maxStrikeInUSD,
            _optionSizeInWEI
        );
        require(
            hasEnoughOTokenLiquidityInOpynV1(_optionSizeInWEI) == true,
            "your size is too big for this oToken liquidity in the Opyn V1"
        );
        if (
            theCheapestETHPutOptionInHegicV888.premiumInWEI <
            theCheapestWETHPutOptionInOpynV1.premiumInWEI ||
            matchedWETHPutOptionOTokenListV1.length == 0
        ) {
            _theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.HegicV888,
                address(0), // NA
                address(0), // NA
                theCheapestETHPutOptionInHegicV888.expiry,
                _optionSizeInWEI,
                theCheapestETHPutOptionInHegicV888.premiumInWEI,
                theCheapestETHPutOptionInHegicV888.strikeInUSD
            );
            emit TheCheapestETHPutOptionGot("hegic v888");
            return _theCheapestETHPutOption;
        } else if (
            theCheapestETHPutOptionInHegicV888.premiumInWEI >
            theCheapestWETHPutOptionInOpynV1.premiumInWEI &&
            matchedWETHPutOptionOTokenListV1.length > 0
        ) {
            _theCheapestETHPutOption = TheCheapestETHPutOption(
                Protocol.OpynV1,
                theCheapestWETHPutOptionInOpynV1.oTokenAddress,
                address(0), // ETH
                theCheapestWETHPutOptionInOpynV1.expiry,
                _optionSizeInWEI,
                theCheapestWETHPutOptionInOpynV1.premiumInWEI,
                theCheapestWETHPutOptionInOpynV1.strikeInUSD
            );
            emit TheCheapestETHPutOptionGot("opyn v1");
            return _theCheapestETHPutOption;
        } else {
            emit TheCheapestETHPutOptionGot("no matches");
        }
    }
}

