// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IHegicETHOptionV888.sol";
import "./interfaces/IHegicETHPoolV888.sol";

contract DeriOneV1HegicV888 is Ownable {
    using SafeMath for uint256;

    // bool public hasEnoughETHLiquidity;

    IHegicETHOptionV888 private HegicETHOptionV888Instance;
    IHegicETHPoolV888 private HegicETHPoolV888Instance;

    IHegicETHOptionV888.OptionType optionType;

    struct TheCheapestETHPutOptionInHegicV888 {
        uint256 expiry;
        uint256 premiumInWEI;
        uint256 strikeInUSD;
    }

    // the cheapest ETH put option in the Hegic V888
    TheCheapestETHPutOptionInHegicV888 theCheapestETHPutOptionInHegicV888;

    constructor(
        address _hegicETHOptionV888Address,
        address _hegicETHPoolV888Address
    ) public {
        instantiateHegicETHOptionV888(_hegicETHOptionV888Address);
        instantiateHegicETHPoolV888(_hegicETHPoolV888Address);
    }

    /// @param _hegicETHOptionV888Address HegicETHOptionV888Address
    function instantiateHegicETHOptionV888(address _hegicETHOptionV888Address)
        public
        onlyOwner
    {
        HegicETHOptionV888Instance = IHegicETHOptionV888(
            _hegicETHOptionV888Address
        );
    }

    /// @param _hegicETHPoolV888Address HegicETHPoolV888Address
    function instantiateHegicETHPoolV888(address _hegicETHPoolV888Address)
        public
        onlyOwner
    {
        HegicETHPoolV888Instance = IHegicETHPoolV888(_hegicETHPoolV888Address);
    }

    /// @param _optionSizeInWEI the size of an option to buy in WEI
    function hasEnoughETHLiquidityInHegicV888(uint256 _optionSizeInWEI)
        internal
        view
        returns (bool)
    {
        // `(Total ETH in contract) * 0.8 - the amount utilized for options`
        // we might or might not need the *0.8 part
        uint256 availableBalance =
            HegicETHPoolV888Instance.totalBalance().mul(8).div(10);
        uint256 amountUtilized =
            HegicETHPoolV888Instance.totalBalance().sub(
                HegicETHPoolV888Instance.availableBalance()
            );

        require(
            availableBalance > amountUtilized,
            "there is not enough available balance"
        );
        uint256 maxOptionSize = availableBalance.sub(amountUtilized);

        // what happens when the value of a uint256 is negative?
        // is this equation right?
        if (maxOptionSize > _optionSizeInWEI) {
            return true;
        } else if (maxOptionSize <= _optionSizeInWEI) {
            return false;
        }
    }

    /// @notice calculate the premium and get the cheapest ETH put option in Hegic v888
    /// @param _minExpiry minimum expiration date in seconds from now
    /// @param _optionSizeInWEI option size in WEI
    /// @param _minStrikeInUSD minimum strike price
    /// @dev does _minExpiry and _minStrikeInUSD always give the cheapest premium?
    function getTheCheapestETHPutOptionInHegicV888(
        uint256 _minExpiry,
        uint256 _optionSizeInWEI,
        uint256 _minStrikeInUSD
    ) internal {
        optionType = IHegicETHOptionV888.OptionType.Put;
        (uint256 minimumPremiumToPayInWEI, , , ) =
            HegicETHOptionV888Instance.fees(
                _minExpiry,
                _optionSizeInWEI,
                _minStrikeInUSD,
                uint8(optionType)
            );

        theCheapestETHPutOptionInHegicV888 = TheCheapestETHPutOptionInHegicV888(
            _minExpiry,
            minimumPremiumToPayInWEI,
            _minStrikeInUSD
        );
    }
}

// you need to use require for strike price and expiry and possibly in other places
// the hegic has some require
// https://github.com/hegic/contracts-v888/blob/ecdc7816c1deef8d2e3cf2629c68807ffdef2cc5/contracts/Options/HegicETHOptions.sol#L121

