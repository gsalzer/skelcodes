// SPDX-License-Identifier: MIT
// Degen Farm. Collectible NFT game
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./DegensFarmBase.sol";

contract DegenFarm is DegenFarmBase {

    uint8   constant public CREATURE_TYPE_COUNT= 20;  //how much creatures types may be used
    uint256 constant public FARMING_DURATION   = 168 hours; //in seconds
    //uint256 constant public NEXT_FARMING_DELAY = 1   weeks;
    uint256 constant public TOOL_UNSTAKE_DELAY = 1   weeks;
    uint256 constant public REVEAL_THRESHOLD   = 810e18;    //90% from MAX_BAGS
    uint16   constant public NORMIE_COUNT_IN_TYPE = 100;
    uint16   constant public CHAD_COUNT_IN_TYPE = 20;
    uint16   constant public MAX_LANDS = 2500;

    constructor (
        address _land,
        address _creatures,
        address _inventory,
        address _bagstoken,
        address _dungtoken,
        IEggs _eggs
    )
        DegenFarmBase(_land, _creatures, _inventory, _bagstoken, _dungtoken, _eggs)
    {
        require(CREATURE_TYPE_COUNT <= CREATURE_TYPE_COUNT_MAX, "CREATURE_TYPE_COUNT is greater than CREATURE_TYPE_COUNT_MAX");

        // Mainnet amulet addrresses
        amulets[0] = [0xD533a949740bb3306d119CC777fa900bA034cd52, 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C];
        amulets[1] = [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0x111111111117dC0aa78b770fA6A738034120C302];
        amulets[2] = [0xE41d2489571d322189246DaFA5ebDe1F4699F498, 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F,
            0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a
        ];
        amulets[3] = [0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000];
        amulets[4] = [0xc00e94Cb662C3520282E6f5717214004A7f26888, 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2,
            0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2
        ];
        amulets[5] = [0x0D8775F648430679A709E98d2b0Cb6250d2887EF, 0x584bC13c7D411c00c01A62e8019472dE68768430];
        amulets[6] = [0x3472A5A71965499acd81997a54BBA8D852C6E53d, 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942];
        amulets[7] = [0x514910771AF9Ca656af840dff83E8264EcF986CA, 0xd7c49CEE7E9188cCa6AD8FF264C1DA2e69D4Cf3B];
        amulets[8] = [0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e, 0x3155BA85D5F96b2d030a4966AF206230e46849cb];
        amulets[9] = [0xa1faa113cbE53436Df28FF0aEe54275c13B40975, 0x3F382DbD960E3a9bbCeaE22651E88158d2791550,
            0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9
        ];
        // TODO: add amulets
        for (uint i = 10; i < CREATURE_TYPE_COUNT; i++) {
            amulets[i] = [0xa1faa113cbE53436Df28FF0aEe54275c13B40975];
        }
    }

    function getCreatureTypeCount() override internal view returns (uint16) {
        return CREATURE_TYPE_COUNT;
    }

    function getFarmingDuration() override internal view returns (uint) {
        return FARMING_DURATION;
    }

    function getNormieCountInType() override internal view returns (uint16) {
        return NORMIE_COUNT_IN_TYPE;
    }

    function getChadCountInType() override internal view returns (uint16) {
        return CHAD_COUNT_IN_TYPE;
    }

    function getMaxLands() override internal view returns (uint16) {
        return MAX_LANDS;
    }

    function getToolUnstakeDelay() override internal view returns (uint) {
        return TOOL_UNSTAKE_DELAY;
    }

}

