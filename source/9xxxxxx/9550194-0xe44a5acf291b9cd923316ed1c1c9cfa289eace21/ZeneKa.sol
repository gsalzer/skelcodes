pragma solidity ^0.5.0;

import "./BN256G2.sol";
import "./Pairing.sol";

contract ZeneKa {
    using Pairing for *;
    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    event Register(bytes32 indexed _id, address indexed _registrant);
    event Commit(
        bytes32 indexed _id,
        bytes32 indexed _proofHash,
        address indexed _prover
    );
    event Verify(
        bytes32 indexed _id,
        bytes32 indexed _proofHash,
        address indexed _prover
    );

    mapping(bytes32 => bytes32) _idToCommit;
    mapping(bytes32 => address) _proofHashToProver;
    mapping(bytes32 => bool) _proofHashToProven;
    mapping(bytes32 => mapping(address => uint256[])) _idToProverToInput;
    mapping(bytes32 => mapping(address => bool)) _idToProverToVerified;

    function _verified(bytes32 _id, bytes32 _proofHash, uint256[] memory _input)
        internal
    {
        _proofHashToProven[_proofHash] = true;
        _idToProverToVerified[_id][msg.sender] = true;
        _idToProverToInput[_id][msg.sender] = _input;
        emit Verify(_id, _proofHash, msg.sender);
    }

    function verify(bytes32 _id, address _address)
        public
        view
        returns (bool isVerified)
    {
        return _idToProverToVerified[_id][_address];
    }

    function input(bytes32 _id, address _prover)
        public
        view
        returns (uint256[] memory zkInput)
    {
        require(_idToProverToVerified[_id][_prover], "Unverified");
        return _idToProverToInput[_id][_prover];
    }
}

