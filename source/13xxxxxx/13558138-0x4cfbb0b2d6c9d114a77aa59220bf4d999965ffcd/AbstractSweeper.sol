//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Controller.sol";
import "./Token.sol";

abstract contract AbstractSweeper {
  Controller internal controller;

  constructor(Controller _controller) {
    controller = _controller;
  }

  modifier canSweep() {
    require(
      msg.sender == controller.authorizedCaller()
      || msg.sender == controller.owner()
      || msg.sender == controller.dev(),
      "not authorized"
    );
    require(controller.halted() == false, "controller is halted");
    _;
  }

  function sweep(address token, uint amount) public virtual returns (bool);

  fallback () payable external { revert(); }
  receive () payable external { revert(); }
}

contract DefaultSweeper is AbstractSweeper {
  constructor(Controller _controller) AbstractSweeper(_controller) {}

  function sweep(address _token, uint _amount) override public canSweep returns (bool) {
    bool success = false;
    address payable destination = controller.destination();

    if (_token != address(0)) {
      Token token = Token(_token);
      uint amount = _amount;
      if (amount > token.balanceOf(address(this))) {
          return false;
      }
      success = token.transfer(destination, amount);
    }
    else {
      uint amountInWei = _amount;
      if (amountInWei > address(this).balance) {
          return false;
      }

      success = destination.send(amountInWei);
    }

    if (success) {
      controller.logSweep(this, destination, _token, _amount);
    }
    return success;
  }
}
