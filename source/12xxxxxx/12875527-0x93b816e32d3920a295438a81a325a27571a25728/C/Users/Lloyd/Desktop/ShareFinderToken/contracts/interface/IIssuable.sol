/* 
 * Copyright (c) Capital Market and Technology Association, 2018-2019
 * https://cmta.ch
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. 
 */
 
pragma solidity ^0.5.3;

/**
 * @title IIssuable
 * @dev IIssuable interface
 *
 * @author Sébastien Krafft - <sebastien.krafft@mtpelerin.com>
 *
 **/


interface IIssuable {
  function issue(uint256 value) external;
  /**
  * Purpose:
  * This event is emitted when new tokens are issued.
  *
  * @param value - amount of newly issued tokens
  */
  event LogIssued(uint256 value);
}

