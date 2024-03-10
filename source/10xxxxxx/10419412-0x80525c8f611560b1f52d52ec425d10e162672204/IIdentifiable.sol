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
 * @title IIdentifiable
 * @dev IIdentifiable interface
 *
 * @author Sébastien Krafft - <sebastien.krafft@mtpelerin.com>
 *
 **/


interface IIdentifiable {
  function identity(address shareholder) external view returns (bytes memory);
  function setMyIdentity(bytes calldata _identity) external;
}

