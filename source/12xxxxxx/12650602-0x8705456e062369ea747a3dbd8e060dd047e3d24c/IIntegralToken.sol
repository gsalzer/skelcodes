// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.5;

interface IIntegralToken {
    function setOwner(address _owner) external;

    function setBlacklisted(address account, bool _isBlacklisted) external;
}

