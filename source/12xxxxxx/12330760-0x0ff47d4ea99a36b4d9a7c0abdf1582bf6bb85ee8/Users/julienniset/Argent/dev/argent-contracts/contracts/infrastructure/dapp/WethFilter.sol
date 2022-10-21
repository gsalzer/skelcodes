// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./BaseFilter.sol";

/**
 * @title WethFilter
 * @notice Filter used for calls to WETH
 * @author Olivier VDB - <olivier@argent.xyz>
 */
contract WethFilter is BaseFilter {

    bytes4 private constant DEPOSIT = bytes4(keccak256("deposit()"));
    bytes4 private constant WITHDRAW = bytes4(keccak256("withdraw(uint256)"));

    function isValid(address /*_wallet*/, address _spender, address _to, bytes calldata _data) external view override returns (bool valid) {
        if (_data.length == 0) {
            return true;
        }
        if (_data.length >= 4) {
            bytes4 methodId = getMethod(_data);
            return (_spender == _to && methodId == DEPOSIT || methodId == WITHDRAW);
        }
    }
}
