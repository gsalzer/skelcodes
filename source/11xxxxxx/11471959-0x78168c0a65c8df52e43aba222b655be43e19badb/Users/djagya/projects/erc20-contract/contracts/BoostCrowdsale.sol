// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/access/roles/WhitelistAdminRole.sol";
import "./crowdsale/WithrawableCrowdsale.sol";
import "./crowdsale/ReferralsCrowdsale.sol";
import "./crowdsale/IndividualCrowdsale.sol";
import "./crowdsale/RoundsCrowdsale.sol";
import "./crowdsale/PostDeliveryCrowdsale.sol";
import "./crowdsale/MinMaxCrowdsale.sol";
import "./crowdsale/WhitelistCrowdsale.sol";
import "./crowdsale/TimedCrowdsale.sol";

/**
 *     ____  ____  ____  ___________
 *    / __ )/ __ \/ __ \/ ___/_  __/
 *   / __  / / / / / / /\__ \ / /
 *  / /_/ / /_/ / /_/ /___/ // /
 * /_____/\____/\____//____//_/
 */
contract BoostCrowdsale is
Ownable,
Crowdsale,
WhitelistAdminRole,
TimedCrowdsale,
WithrawableCrowdsale,
MinMaxCrowdsale,
PostDeliveryCrowdsale,
RoundsCrowdsale,
ReferralsCrowdsale,
IndividualCrowdsale
{
    using SafeMath for uint256;

    uint constant ROUNDS = 1;
    uint256 constant ROUND_CAP = 195000 ether;
    uint256 constant INIT_RATE = 2500;
    uint256 constant RATE_DECREMENT = 150;

    constructor(
        IERC20 token,
        uint256 openingTime,
        uint256 closingTime
    )
    Crowdsale(INIT_RATE, msg.sender, token)
    RoundsCrowdsale(ROUNDS, ROUND_CAP, INIT_RATE, RATE_DECREMENT)
    TimedCrowdsale(block.timestamp, closingTime)
    public {}
}

