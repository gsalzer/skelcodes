// SPDX-License-Identifier: AGPL-3.0-only

/*
    SkaleDkgAlright.sol - SKALE Manager
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Artem Payvin
    @author Vadim Yavorsky

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
import "../ContractManager.sol";
import "../Wallets.sol";
import "../KeyStorage.sol";

/**
 * @title SkaleDkgAlright
 * @dev Contains functions to manage distributed key generation per
 * Joint-Feldman protocol.
 */
library SkaleDkgAlright {

    event AllDataReceived(bytes32 indexed schainHash, uint nodeIndex);
    event SuccessfulDKG(bytes32 indexed schainHash);

    function alright(
        bytes32 schainHash,
        uint fromNodeIndex,
        ContractManager contractManager,
        mapping(bytes32 => SkaleDKG.Channel) storage channels,
        mapping(bytes32 => SkaleDKG.ProcessDKG) storage dkgProcess,
        mapping(bytes32 => SkaleDKG.ComplaintData) storage complaints,
        mapping(bytes32 => uint) storage lastSuccessfulDKG
        
    )
        external
    {
        SkaleDKG skaleDKG = SkaleDKG(contractManager.getContract("SkaleDKG"));
        (uint index, ) = skaleDKG.checkAndReturnIndexInGroup(schainHash, fromNodeIndex, true);
        uint numberOfParticipant = channels[schainHash].n;
        require(numberOfParticipant == dkgProcess[schainHash].numberOfBroadcasted, "Still Broadcasting phase");
        require(
            complaints[schainHash].fromNodeToComplaint != fromNodeIndex ||
            (fromNodeIndex == 0 && complaints[schainHash].startComplaintBlockTimestamp == 0),
            "Node has already sent complaint"
        );
        require(!dkgProcess[schainHash].completed[index], "Node is already alright");
        dkgProcess[schainHash].completed[index] = true;
        dkgProcess[schainHash].numberOfCompleted++;
        emit AllDataReceived(schainHash, fromNodeIndex);
        if (dkgProcess[schainHash].numberOfCompleted == numberOfParticipant) {
            lastSuccessfulDKG[schainHash] = now;
            channels[schainHash].active = false;
            KeyStorage(contractManager.getContract("KeyStorage")).finalizePublicKey(schainHash);
            emit SuccessfulDKG(schainHash);
        }
    }

}
