pragma solidity ^0.6.3;

import "./ZeneKa.sol";

// Based on ZoKrates Verifier @ https://github.com/Zokrates/ZoKrates

contract ZeneKaGM17 is ZeneKa {
    struct VerifyingKeyGM17 {
        Pairing.G2Point h;
        Pairing.G1Point g_alpha;
        Pairing.G2Point h_beta;
        Pairing.G1Point g_gamma;
        Pairing.G2Point h_gamma;
        Pairing.G1Point[] query;
    }

    struct ProofGM17 {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }

    struct ParamsGM17 {
        bytes32[2][2] h;
        bytes32[2] g_alpha;
        bytes32[2][2] h_beta;
        bytes32[2] g_gamma;
        bytes32[2][2] h_gamma;
        uint256 query_len;
        bytes32[2][] query;
        bool registered;
    }

    mapping(bytes32 => ParamsGM17) private _idToVkParamsGM17;

    function _verifyingKeyGM17(bytes32 _id)
        internal
        view
        returns (VerifyingKeyGM17 memory vk)
    {
        ParamsGM17 memory params = _idToVkParamsGM17[_id];

        vk.h = Pairing.G2Point(
            [uint256(params.h[0][0]), uint256(params.h[0][1])],
            [uint256(params.h[1][0]), uint256(params.h[1][1])]
        );
        vk.g_alpha = Pairing.G1Point(
            uint256(params.g_alpha[0]),
            uint256(params.g_alpha[1])
        );
        vk.h_beta = Pairing.G2Point(
            [uint256(params.h_beta[0][0]), uint256(params.h_beta[0][1])],
            [uint256(params.h_beta[1][0]), uint256(params.h_beta[1][1])]
        );
        vk.g_gamma = Pairing.G1Point(
            uint256(params.g_gamma[0]),
            uint256(params.g_gamma[1])
        );
        vk.h_gamma = Pairing.G2Point(
            [uint256(params.h_gamma[0][0]), uint256(params.h_gamma[0][1])],
            [uint256(params.h_gamma[1][0]), uint256(params.h_gamma[1][1])]
        );
        vk.query = new Pairing.G1Point[](params.query_len);
        for (uint256 i = 0; i < params.query_len; i++) {
            vk.query[i] = Pairing.G1Point(
                uint256(params.query[i][0]),
                uint256(params.query[i][1])
            );
        }
    }

    function registerGM17(
        bytes32[2][2] memory _h,
        bytes32[2] memory _g_alpha,
        bytes32[2][2] memory _h_beta,
        bytes32[2] memory _g_gamma,
        bytes32[2][2] memory _h_gamma,
        uint256 _query_len,
        bytes32[2][] memory _query
    ) public returns (bool isRegistered) {
        bytes32 id = keccak256(
            abi.encodePacked(
                _h,
                _g_alpha,
                _h_beta,
                _g_gamma,
                _h_gamma,
                _query_len,
                _query
            )
        );

        if (_idToVkParamsGM17[id].registered) return true;

        _idToVkParamsGM17[id] = ParamsGM17({
            h: _h,
            g_alpha: _g_alpha,
            h_beta: _h_beta,
            g_gamma: _g_gamma,
            h_gamma: _h_gamma,
            query_len: _query_len,
            query: _query,
            registered: true
        });

        emit Register(id, msg.sender);
        return true;
    }

    function commitGM17(bytes32 _id, bytes32 _proofHash)
        public
        returns (bool didCommit)
    {
        // Stores a proof hash (throws if pre-existing value)
        if (
            !_idToVkParamsGM17[_id].registered ||
            _proofHashToProver[_proofHash] != address(0)
        ) return false;
        _proofHashToProver[_proofHash] = msg.sender;
        emit Commit(_id, _proofHash, msg.sender);
        return true;
    }

    function proveGM17(
        bytes32 _id,
        uint256[2] memory _a,
        uint256[2][2] memory _b,
        uint256[2] memory _c,
        uint256[] memory _input
    ) public returns (bool isValid) {
        bytes32 proofHash = keccak256(abi.encodePacked(_a, _b, _c, _input));
        if (_proofHashToProven[proofHash]) return true;
        if (
            !_idToVkParamsGM17[_id].registered ||
            _proofHashToProver[proofHash] != msg.sender
        ) return false;

        VerifyingKeyGM17 memory vk = _verifyingKeyGM17(_id);
        if (_input.length + 1 != _idToVkParamsGM17[_id].query_len) return false;
        ProofGM17 memory proof;
        proof.a = Pairing.G1Point(_a[0], _a[1]);
        proof.b = Pairing.G2Point([_b[0][0], _b[0][1]], [_b[1][0], _b[1][1]]);
        proof.c = Pairing.G1Point(_c[0], _c[1]);

        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint256 i = 0; i < _input.length; i++) {
            if (_input[i] >= SNARK_SCALAR_FIELD) return false;
            vk_x = Pairing.addition(
                vk_x,
                Pairing.scalar_mul(vk.query[i + 1], _input[i])
            );
        }
        vk_x = Pairing.addition(vk_x, vk.query[0]);
        if (
            !Pairing.pairingProd4(
                vk.g_alpha,
                vk.h_beta,
                vk_x,
                vk.h_gamma,
                proof.c,
                vk.h,
                Pairing.negate(Pairing.addition(proof.a, vk.g_alpha)),
                Pairing.addition(proof.b, vk.h_beta)
            ) ||
            !Pairing.pairingProd2(
                proof.a,
                vk.h_gamma,
                Pairing.negate(vk.g_gamma),
                proof.b
            )
        ) return false;

        _verified(_id, proofHash, _input);
        return true;
    }
}

