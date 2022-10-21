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
import "./ECDH.sol";
import "./Precompiled.sol";
import "./FieldOperations.sol";

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

    function deleteKey(bytes32 schainId) external allow("SkaleDKG") {
        _previousSchainsPublicKeys[schainId].push(_schainsPublicKeys[schainId]);
        delete _schainsPublicKeys[schainId];
    }

    function initPublicKeyInProgress(bytes32 schainId) external allow("SkaleDKG") {
        _publicKeysInProgress[schainId] = G2Operations.getG2Zero();
    }

    function adding(bytes32 schainId, G2Operations.G2Point memory value) external allow("SkaleDKG") {
        require(value.isG2(), "Incorrect g2 point");
        _publicKeysInProgress[schainId] = value.addG2(_publicKeysInProgress[schainId]);
    }

    function finalizePublicKey(bytes32 schainId) external allow("SkaleDKG") {
        if (!_isSchainsPublicKeyZero(schainId)) {
            _previousSchainsPublicKeys[schainId].push(_schainsPublicKeys[schainId]);
        }
        _schainsPublicKeys[schainId] = _publicKeysInProgress[schainId];
        delete _publicKeysInProgress[schainId];
    }

    function getCommonPublicKey(bytes32 schainId) external view returns (G2Operations.G2Point memory) {
        return _schainsPublicKeys[schainId];
    }

    function getPreviousPublicKey(bytes32 schainId) external view returns (G2Operations.G2Point memory) {
        uint length = _previousSchainsPublicKeys[schainId].length;
        if (length == 0) {
            return G2Operations.getG2Zero();
        }
        return _previousSchainsPublicKeys[schainId][length - 1];
    }

    function getAllPreviousPublicKeys(bytes32 schainId) external view returns (G2Operations.G2Point[] memory) {
        return _previousSchainsPublicKeys[schainId];
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
    }

    function _isSchainsPublicKeyZero(bytes32 schainId) private view returns (bool) {
        return _schainsPublicKeys[schainId].x.a == 0 &&
            _schainsPublicKeys[schainId].x.b == 0 &&
            _schainsPublicKeys[schainId].y.a == 0 &&
            _schainsPublicKeys[schainId].y.b == 0;
    }

    function _getData() private view returns (BroadcastedData memory) {
        return _data[keccak256(abi.encodePacked("UnusedFunction"))][0];
    }

    function _getNodesPublicKey() private view returns (G2Operations.G2Point memory) {
        return _schainsNodesPublicKeys[keccak256(abi.encodePacked("UnusedFunction"))][0];
    }
}
