// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "./ControlledTokenProxyFactory.sol";
import "./TicketProxyFactory.sol";

/* solium-disable security/no-block-members */
contract ControlledTokenBuilder {

  event CreatedControlledToken(address indexed token);
  event CreatedTicket(address indexed token);

  ControlledTokenProxyFactory public controlledTokenProxyFactory;
  TicketProxyFactory public ticketProxyFactory;

  struct ControlledTokenConfig {
    string name;
    string symbol;
    uint8 decimals;
    TokenControllerInterface controller;
  }

  constructor (
    ControlledTokenProxyFactory _controlledTokenProxyFactory,
    TicketProxyFactory _ticketProxyFactory
  ) public {
    require(address(_controlledTokenProxyFactory) != address(0), "CONTROLLEDTOKENBUILDER: CONTROLLEDTOKENPROXYFACTORY_NOT_ZERO");
    require(address(_ticketProxyFactory) != address(0), "CONTROLLEDTOKENBUILDER: TICKETPROXYFACTORY_NOT_ZERO");
    controlledTokenProxyFactory = _controlledTokenProxyFactory;
    ticketProxyFactory = _ticketProxyFactory;
  }

  function createControlledToken(
    ControlledTokenConfig calldata config
  ) external returns (ControlledToken) {
    ControlledToken token = controlledTokenProxyFactory.create();

    token.initialize(
      config.name,
      config.symbol,
      config.decimals,
      config.controller
    );

    emit CreatedControlledToken(address(token));

    return token;
  }

  function createTicket(
    ControlledTokenConfig calldata config
  ) external returns (Ticket) {
    Ticket token = ticketProxyFactory.create();

    token.initialize(
      config.name,
      config.symbol,
      config.decimals,
      config.controller
    );

    emit CreatedTicket(address(token));

    return token;
  }
}

