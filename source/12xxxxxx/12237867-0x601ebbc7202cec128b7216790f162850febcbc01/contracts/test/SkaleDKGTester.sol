// SPDX-License-Identifier: AGPL-3.0-only

/*
    SkaleDKGTester.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "../SkaleDKG.sol";

contract SkaleDKGTester is SkaleDKG {
    function setSuccessfulDKGPublic(bytes32 schainId) external {
        lastSuccesfulDKG[schainId] = now;
        channels[schainId].active = false;
        KeyStorage(contractManager.getContract("KeyStorage")).finalizePublicKey(schainId);
        emit SuccessfulDKG(schainId);
    }
}

