// SPDX-License-Identifier: AGPL-3.0-only

/*
    KeyStorage.sol - SKALE Manager
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
import "./Decryption.sol";
import "./Permissions.sol";
import "./SchainsInternal.sol";
import "./thirdparty/ECDH.sol";
import "./utils/Precompiled.sol";
import "./utils/FieldOperations.sol";

contract KeyStorage is Permissions {
    using Fp2Operations for Fp2Operations.Fp2Point;
    using G2Operations for G2Operations.G2Point;

    struct BroadcastedData {
        KeyShare[] secretKeyContribution;
        G2Operations.G2Point[] verificationVector;
    }

    struct KeyShare {
        bytes32[2] publicKey;
        bytes32 share;
    }

    // Unused variable!!
    mapping(bytes32 => mapping(uint => BroadcastedData)) private _data;
    // 
    
    mapping(bytes32 => G2Operations.G2Point) private _publicKeysInProgress;
    mapping(bytes32 => G2Operations.G2Point) private _schainsPublicKeys;

    // Unused variable
    mapping(bytes32 => G2Operations.G2Point[]) private _schainsNodesPublicKeys;
    //

    mapping(bytes32 => G2Operations.G2Point[]) private _previousSchainsPublicKeys;

    function deleteKey(bytes32 schainHash) external allow("SkaleDKG") {
        _previousSchainsPublicKeys[schainHash].push(_schainsPublicKeys[schainHash]);
        delete _schainsPublicKeys[schainHash];
        delete _data[schainHash][0];
        delete _schainsNodesPublicKeys[schainHash];
    }

    function initPublicKeyInProgress(bytes32 schainHash) external allow("SkaleDKG") {
        _publicKeysInProgress[schainHash] = G2Operations.getG2Zero();
    }

    function adding(bytes32 schainHash, G2Operations.G2Point memory value) external allow("SkaleDKG") {
        require(value.isG2(), "Incorrect g2 point");
        _publicKeysInProgress[schainHash] = value.addG2(_publicKeysInProgress[schainHash]);
    }

    function finalizePublicKey(bytes32 schainHash) external allow("SkaleDKG") {
        if (!_isSchainsPublicKeyZero(schainHash)) {
            _previousSchainsPublicKeys[schainHash].push(_schainsPublicKeys[schainHash]);
        }
        _schainsPublicKeys[schainHash] = _publicKeysInProgress[schainHash];
        delete _publicKeysInProgress[schainHash];
    }

    function getCommonPublicKey(bytes32 schainHash) external view returns (G2Operations.G2Point memory) {
        return _schainsPublicKeys[schainHash];
    }

    function getPreviousPublicKey(bytes32 schainHash) external view returns (G2Operations.G2Point memory) {
        uint length = _previousSchainsPublicKeys[schainHash].length;
        if (length == 0) {
            return G2Operations.getG2Zero();
        }
        return _previousSchainsPublicKeys[schainHash][length - 1];
    }

    function getAllPreviousPublicKeys(bytes32 schainHash) external view returns (G2Operations.G2Point[] memory) {
        return _previousSchainsPublicKeys[schainHash];
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
    }

    function _isSchainsPublicKeyZero(bytes32 schainHash) private view returns (bool) {
        return _schainsPublicKeys[schainHash].x.a == 0 &&
            _schainsPublicKeys[schainHash].x.b == 0 &&
            _schainsPublicKeys[schainHash].y.a == 0 &&
            _schainsPublicKeys[schainHash].y.b == 0;
    }
}
