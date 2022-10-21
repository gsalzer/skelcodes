// SPDX-License-Identifier: MIT

pragma solidity =0.5.16;

import {Ownable} from '../libraries/Ownable.sol';
import {SafeMath} from '../libraries/SafeMath.sol';
import {UQ112x112} from '../libraries/UQ112x112.sol';
import {IBurnableERC20} from '../interfaces/IBurnableERC20.sol';
import {IUniswapOracle} from '../interfaces/IUniswapOracle.sol';
import {IChainlinkAggregatorV3} from '../interfaces/IChainlinkAggregatorV3.sol';

/**
 * NOTE: Contract MahaswapV1Pair should be the owner of this controller.
 */
contract State is Ownable {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    // Token which will be used to charge penalty or reward incentives.
    IBurnableERC20 public incentiveToken;

    // Pair that will be using this contract.
    address public pairAddress;

    // Token which is the main token of a protocol.
    address public protocolTokenAddress;

    // A fraction of penalty is being used to fund the ecosystem.
    address ecosystemFund;

    // Used to track the latest twap price.
    IUniswapOracle public uniswapOracle;

    // Chainlink price feed for non-protocol token to get price in USD terms.
    // Quote is non-protocol token. (Dai in case of ARTH-DAI pair)
    IChainlinkAggregatorV3 public quotePriceFeed;

    // Default price of when reward is to be given.
    uint256 public rewardPrice = uint256(100).mul(1e16); // ~1$
    // Default price of when penalty is to be charged.
    uint256 public penaltyPrice = uint256(100).mul(1e16); // ~1$

    // Should we use oracle to get diff. price feeds or not.
    bool public useOracle = false;

    bool public isTokenAProtocolToken = true;

    // Max. reward per hour to be given out.
    uint256 public rewardPerEpoch = 0;

    // Multipiler for rewards and penalty.
    uint256 public rewardMultiplier = 5 * 100000; // 5x
    uint256 public penaltyMultiplier = 200 * 100000; // 200x

    // Percentage of penalty to be burnt from the token's supply.
    uint256 public penaltyToBurn = uint256(45); // In %.
    // Percentage of penalty to be kept inside this contract to act as fund for rewards.
    uint256 public penaltyToKeep = uint256(45); // In %.
    // Percentage of penalty to be redirected to diff. funds(currently ecosystem fund).
    uint256 public penaltyToRedirect = uint256(10); // In %.

    // The reward which can be given out during this epoch.
    uint256 public availableRewardThisEpoch = 0;
    uint256 public rewardsThisEpoch = 0;

    // The reward which has been collected through the penalities accross all epochs.
    uint256 public rewardCollectedFromPenalties = 0;

    uint256 public arthToMahaRate;

    /**
     * Modifier.
     */
    modifier onlyPair {
        require(msg.sender == pairAddress, 'Controller: Forbidden');
        _;
    }
}

