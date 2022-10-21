/**

    The software and documentation available in this repository (the "Software") is
    protected by copyright law and accessible pursuant to the license set forth below.

    Copyright © 2019 Staked Securely, Inc. All rights reserved.

    Permission is hereby granted, free of charge, to any person or organization
    obtaining the Software (the “Licensee”) to privately study, review, and analyze
    the Software. Licensee shall not use the Software for any other purpose. Licensee
    shall not modify, transfer, assign, share, or sub-license the Software or any
    derivative works of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
    PARTICULAR PURPOSE, TITLE, AND NON-INFRINGEMENT. IN NO EVENT SHALL THE COPYRIGHT
    HOLDERS BE LIABLE FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT,
    OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE.

*/

pragma solidity 0.4.25;


/// @notice  Inherited by any contract that is upgradeable.
///
/// @dev     We currently have this method as a safety measure in case we are
///          still referencing an old contract somewhere in the system. We call
///          call this which turns on a flag that forces all calls to revert.
///
///          I now think it may be overkill and a waste to have this on every contract
///          public function, it should only be on the public-facing open functions
///          that the users are interacting with - in case our web-app is pointing
///          to the wrong PortfolioManager still. Internally, it shouldn't it be needed
///          assuming we didn't forget to set the references...my only reason to remove
///          it from most of the contracts is it costs a ton of extra gas - leaving it
///          for now since ToB said it's a good safety measure.

interface Upgradeable {


  /// @notice  Sets a flag in the contract that reverts all calls to it
  function setDeprecated(bool value) external;

}

