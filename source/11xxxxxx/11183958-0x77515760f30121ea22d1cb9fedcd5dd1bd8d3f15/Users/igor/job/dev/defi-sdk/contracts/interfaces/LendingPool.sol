// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

/**
 * @dev LendingPool contract interface.
 * Only the functions required for AaveDebtAdapter contract are added.
 * The LendingPool contract is available here
 * github.com/aave/aave-protocol/blob/master/contracts/lendingpool/LendingPool.sol.
 */
interface LendingPool {
    function deposit(
        address,
        uint256,
        uint16
    ) external payable;

    function getUserReserveData(address, address) external view returns (uint256, uint256);
}

