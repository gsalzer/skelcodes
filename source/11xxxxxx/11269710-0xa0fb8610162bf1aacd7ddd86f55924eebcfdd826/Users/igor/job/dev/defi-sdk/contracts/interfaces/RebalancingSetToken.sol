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

/**
 * @dev RebalancingSetToken contract interface.
 * The RebalancingSetToken contract is available here
 * github.com/SetProtocol/set-protocol-contracts/blob/master/contracts/core/tokens/RebalancingSetTokenV3.sol.
 */
interface RebalancingSetToken {
    function currentSet() external view returns (address);

    function getUnits() external view returns (uint256[] memory);

    function naturalUnit() external view returns (uint256);

    function unitShares() external view returns (uint256);
}

