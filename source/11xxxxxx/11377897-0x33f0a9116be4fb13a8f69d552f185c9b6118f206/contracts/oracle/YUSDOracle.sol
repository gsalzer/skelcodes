// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import {Decimal} from "../lib/Decimal.sol";
import {SafeMath} from "../lib/SafeMath.sol";

import {IOracle} from "./IOracle.sol";
import {IRiskOracle} from "./IRiskOracle.sol";
import {IYToken} from "./IYToken.sol";
import {IChainLinkAggregator} from "./IChainLinkAggregator.sol";

contract YUSDOracle is IOracle {

    using SafeMath for uint256;

    uint256 constant BASE = 10**18;

    IRiskOracle public aaveRiskOracle;

    address public yUSDAddress;

    constructor()
        public
    {
        yUSDAddress = 0x5dbcF33D8c2E976c6b560249878e6F1491Bca25c;
        aaveRiskOracle = IRiskOracle(0x4CC91E0c97c5128247E71a5DdF01CA46f4fa8d1d);
    }

    function fetchCurrentPrice()
        external
        view
        returns (Decimal.D256 memory)
    {
        uint256 yUSDPricePerFullShare = IYToken(yUSDAddress).getPricePerFullShare();

        // It's safe to typecast here since Aave's risk oracle has a backup oracles
        // if the price drops below $0 in the original signed int.
        uint256 priceOfYPoolToken = uint256(aaveRiskOracle.latestAnswer());

        uint256 result = yUSDPricePerFullShare.mul(priceOfYPoolToken).div(BASE);

        require(
            result > 0,
            "YUSDOracle: cannot report a price of 0"
        );

        return Decimal.D256({
            value: result
        });
    }

}

