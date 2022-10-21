// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./ControlledTokenBuilder.sol";
import "./MultipleWinnersProxyFactory.sol";

/* solium-disable security/no-block-members */
contract MultipleWinnersBuilder {

  event MultipleWinnersCreated(address indexed prizeStrategy);

  struct MultipleWinnersConfig {
    RNGInterface rngService;
    uint256 prizePeriodStart;
    uint256 prizePeriodSeconds;
    string ticketName;
    string ticketSymbol;
    string sponsorshipName;
    string sponsorshipSymbol;
    uint256 ticketCreditLimitMantissa;
    uint256 ticketCreditRateMantissa;
    uint256 numberOfWinners;
    bool splitExternalErc20Awards;
  }

  MultipleWinnersProxyFactory public multipleWinnersProxyFactory;
  ControlledTokenBuilder public controlledTokenBuilder;

  constructor (
    MultipleWinnersProxyFactory _multipleWinnersProxyFactory,
    ControlledTokenBuilder _controlledTokenBuilder
  ) public {
    require(address(_multipleWinnersProxyFactory) != address(0), "MULTIPLEWINNERSBUILDER: MULTIPLEWINNERSPROXYFACTORY_NOT_ZERO");
    require(address(_controlledTokenBuilder) != address(0), "MULTIPLEWINNERSBUILDER:TOKEN_BUILDER_NOT_ZERO");
    multipleWinnersProxyFactory = _multipleWinnersProxyFactory;
    controlledTokenBuilder = _controlledTokenBuilder;
  }

  function createMultipleWinners(
    PrizePool prizePool,
    MultipleWinnersConfig memory prizeStrategyConfig,
    uint8 decimals,
    address owner
  ) external returns (MultipleWinners) {
    MultipleWinners mw = multipleWinnersProxyFactory.create();

    Ticket ticket = _createTicket(
      prizeStrategyConfig.ticketName,
      prizeStrategyConfig.ticketSymbol,
      decimals,
      prizePool
    );

    ControlledToken sponsorship = _createSponsorship(
      prizeStrategyConfig.sponsorshipName,
      prizeStrategyConfig.sponsorshipSymbol,
      decimals,
      prizePool
    );

    mw.initializeMultipleWinners(
      prizeStrategyConfig.prizePeriodStart,
      prizeStrategyConfig.prizePeriodSeconds,
      prizePool,
      ticket,
      sponsorship,
      prizeStrategyConfig.rngService,
      prizeStrategyConfig.numberOfWinners
    );

    if (prizeStrategyConfig.splitExternalErc20Awards) {
      mw.setSplitExternalErc20Awards(true);
    }

    mw.transferOwnership(owner);
    emit MultipleWinnersCreated(address(mw));

    return mw;
  }

  function createMultipleWinnersFromExistingPrizeStrategy(
    PeriodicPrizeStrategy prizeStrategy,
    uint256 numberOfWinners
  ) external returns (MultipleWinners) {
    MultipleWinners mw = multipleWinnersProxyFactory.create();

    mw.initializeMultipleWinners(
      prizeStrategy.prizePeriodStartedAt(),
      prizeStrategy.prizePeriodSeconds(),
      prizeStrategy.prizePool(),
      prizeStrategy.ticket(),
      prizeStrategy.sponsorship(),
      prizeStrategy.rng(),
      numberOfWinners
    );

    mw.transferOwnership(msg.sender);
    emit MultipleWinnersCreated(address(mw));

    return mw;
  }

  function _createTicket(
    string memory name,
    string memory token,
    uint8 decimals,
    PrizePool prizePool
  ) internal returns (Ticket) {
    return controlledTokenBuilder.createTicket(
      ControlledTokenBuilder.ControlledTokenConfig(
        name,
        token,
        decimals,
        prizePool
      )
    );
  }

  function _createSponsorship(
    string memory name,
    string memory token,
    uint8 decimals,
    PrizePool prizePool
  ) internal returns (ControlledToken) {
    return controlledTokenBuilder.createControlledToken(
      ControlledTokenBuilder.ControlledTokenConfig(
        name,
        token,
        decimals,
        prizePool
      )
    );
  }
}

