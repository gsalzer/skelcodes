/*

  Copyright 2017 Loopring Project Ltd (Loopring Foundation).

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
pragma solidity ^0.5.11;


/// @title Ownable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
        public
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

/// @title Claimable
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

/// @title ReentrancyGuard
/// @author Brecht Devos - <brecht@loopring.org>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    // Use this modifier on a function to prevent reentrancy
    modifier nonReentrant()
    {
        // Check if the guard value has its original value
        require(_guardValue == 0, "REENTRANCY");

        // Set the value to something else
        _guardValue = 1;

        // Function body
        _;

        // Set the value back
        _guardValue = 0;
    }
}

library Verifier
{
    function ScalarField ()
        internal
        pure
        returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }


    /*
    * This implements the Solidity equivalent of the following Python code:

        from py_ecc.bn128 import *

        data = # ... arguments to function [in_vk, vk_gammaABC, in_proof, proof_inputs]

        vk = [int(_, 16) for _ in data[0]]
        ic = [FQ(int(_, 16)) for _ in data[1]]
        proof = [int(_, 16) for _ in data[2]]
        inputs = [int(_, 16) for _ in data[3]]

        it = iter(ic)
        ic = [(_, next(it)) for _ in it]
        vk_alpha = [FQ(_) for _ in vk[:2]]
        vk_beta = (FQ2(vk[2:4][::-1]), FQ2(vk[4:6][::-1]))
        vk_gamma = (FQ2(vk[6:8][::-1]), FQ2(vk[8:10][::-1]))
        vk_delta = (FQ2(vk[10:12][::-1]), FQ2(vk[12:14][::-1]))

        assert is_on_curve(vk_alpha, b)
        assert is_on_curve(vk_beta, b2)
        assert is_on_curve(vk_gamma, b2)
        assert is_on_curve(vk_delta, b2)

        proof_A = [FQ(_) for _ in proof[:2]]
        proof_B = (FQ2(proof[2:4][::-1]), FQ2(proof[4:-2][::-1]))
        proof_C = [FQ(_) for _ in proof[-2:]]

        assert is_on_curve(proof_A, b)
        assert is_on_curve(proof_B, b2)
        assert is_on_curve(proof_C, b)

        vk_x = ic[0]
        for i, s in enumerate(inputs):
            vk_x = add(vk_x, multiply(ic[i + 1], s))

        check_1 = pairing(proof_B, proof_A)
        check_2 = pairing(vk_beta, neg(vk_alpha))
        check_3 = pairing(vk_gamma, neg(vk_x))
        check_4 = pairing(vk_delta, neg(proof_C))

        ok = check_1 * check_2 * check_3 * check_4
        assert ok == FQ12.one()
    */
    function Verify(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory in_proof,
        uint256[] memory proof_inputs
        )
        internal
        view
        returns (bool)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length, "INVALID_VALUE");

        // Compute the linear combination vk_x
        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint m = 2;

        // First two fields are used as the sum
        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];

        // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
        for (uint i = 0; i < proof_inputs.length; i++) {
            require(proof_inputs[i] < snark_scalar_field, "INVALID_INPUT");
            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];

            assembly {
                // ECMUL, output to last 2 elements of `add_input`
                success := staticcall(sub(gas, 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            if (!success) {
                return false;
            }

            assembly {
                // ECADD
                success := staticcall(sub(gas, 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            if (!success) {
                return false;
            }
        }

        uint[24] memory input = [
            // (proof.A, proof.B)
            in_proof[0], in_proof[1],                           // proof.A   (G1)
            in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)

            // (-vk.alpha, vk.beta)
            in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)

            // (-vk_x, vk.gamma)
            add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)

            // (-proof.C, vk.delta)
            in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
        ];

        uint[1] memory out;
        assembly {
            success := staticcall(sub(gas, 2000), 8, input, 768, out, 0x20)
        }
        return success && out[0] != 0;
    }
}

library BatchVerifier {
    function GroupOrder ()
        public pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }

    function getProofEntropy(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint proofNumber
    )
        internal pure returns (uint256)
    {
        // Truncate the least significant 3 bits from the 256bit entropy so it fits the scalar field
        return uint256(
            keccak256(
                abi.encodePacked(
                    in_proof[proofNumber*8 + 0], in_proof[proofNumber*8 + 1], in_proof[proofNumber*8 + 2], in_proof[proofNumber*8 + 3],
                    in_proof[proofNumber*8 + 4], in_proof[proofNumber*8 + 5], in_proof[proofNumber*8 + 6], in_proof[proofNumber*8 + 7],
                    proof_inputs[proofNumber]
                )
            )
        ) >> 3;
    }

    function accumulate(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    ) internal view returns (
        bool success,
        uint256[] memory proofsAandC,
        uint256[] memory inputAccumulators
    ) {
        uint256 q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 numPublicInputs = proof_inputs.length / num_proofs;
        uint256[] memory entropy = new uint256[](num_proofs);
        inputAccumulators = new uint256[](numPublicInputs + 1);

        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            if (proofNumber == 0) {
                entropy[proofNumber] = 1;
            } else {
                // entropy[proofNumber] = uint256(blockhash(block.number - proofNumber)) % q;
                // Safer entropy:
                entropy[proofNumber] = getProofEntropy(in_proof, proof_inputs, proofNumber);
            }
            require(entropy[proofNumber] != 0, "Entropy should not be zero");
            // here multiplication by 1 is implied
            inputAccumulators[0] = addmod(inputAccumulators[0], entropy[proofNumber], q);
            for (uint256 i = 0; i < numPublicInputs; i++) {
                require(proof_inputs[proofNumber * numPublicInputs + i] < q, "INVALID_INPUT");
                // accumulate the exponent with extra entropy mod q
                inputAccumulators[i+1] = addmod(inputAccumulators[i+1], mulmod(entropy[proofNumber], proof_inputs[proofNumber * numPublicInputs + i], q), q);
            }
            // coefficient for +vk.alpha (mind +) is the same as inputAccumulator[0]
        }

        // inputs for scalar multiplication
        uint256[3] memory mul_input;

        // use scalar multiplications to get proof.A[i] * entropy[i]

        proofsAandC = new uint256[](num_proofs*2 + 2);

        proofsAandC[0] = in_proof[0];
        proofsAandC[1] = in_proof[1];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            require(entropy[proofNumber] < q, "INVALID_INPUT");
            mul_input[0] = in_proof[proofNumber*8];
            mul_input[1] = in_proof[proofNumber*8 + 1];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA[i]
                // success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, add(add(proofsAandC, 0x20), mul(proofNumber, 0x40)), 0x40)
                success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, mul_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
            proofsAandC[proofNumber*2] = mul_input[0];
            proofsAandC[proofNumber*2 + 1] = mul_input[1];
        }

        // use scalar multiplication and addition to get sum(proof.C[i] * entropy[i])

        uint256[4] memory add_input;

        add_input[0] = in_proof[6];
        add_input[1] = in_proof[7];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            mul_input[0] = in_proof[proofNumber*8 + 6];
            mul_input[1] = in_proof[proofNumber*8 + 7];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA
                success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }

            assembly {
                // ECADD from two elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas, 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
        }

        proofsAandC[num_proofs*2] = add_input[0];
        proofsAandC[num_proofs*2 + 1] = add_input[1];
    }

    function prepareBatches(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory inputAccumulators
    ) internal view returns (
        bool success,
        uint256[4] memory finalVksAlphaX
    ) {
        // Compute the linear combination vk_x using accumulator
        // First two fields are used as the sum and are initially zero
        uint256[4] memory add_input;
        uint256[3] memory mul_input;

        // Performs a sum(gammaABC[i] * inputAccumulator[i])
        for (uint256 i = 0; i < inputAccumulators.length; i++) {
            mul_input[0] = vk_gammaABC[2*i];
            mul_input[1] = vk_gammaABC[2*i + 1];
            mul_input[2] = inputAccumulators[i];

            assembly {
                // ECMUL, output to the last 2 elements of `add_input`
                success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }

            assembly {
                // ECADD from four elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas, 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }
        }

        finalVksAlphaX[2] = add_input[0];
        finalVksAlphaX[3] = add_input[1];

        // add one extra memory slot for scalar for multiplication usage
        uint256[3] memory finalVKalpha;
        finalVKalpha[0] = in_vk[0];
        finalVKalpha[1] = in_vk[1];
        finalVKalpha[2] = inputAccumulators[0];

        assembly {
            // ECMUL, output to first 2 elements of finalVKalpha
            success := staticcall(sub(gas, 2000), 7, finalVKalpha, 0x60, finalVKalpha, 0x40)
        }
        if (!success) {
            return (false, finalVksAlphaX);
        }

        finalVksAlphaX[0] = finalVKalpha[0];
        finalVksAlphaX[1] = finalVKalpha[1];
    }

    // original equation
    // e(proof.A, proof.B)*e(-vk.alpha, vk.beta)*e(-vk_x, vk.gamma)*e(-proof.C, vk.delta) == 1
    // accumulation of inputs
    // gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]

    function BatchVerify (
        uint256[14] memory in_vk, // verifying key is always constant number of elements
        uint256[4] memory vk_gammaABC, // variable length, depends on number of inputs
        uint256[] memory in_proof, // proof itself, length is 8 * num_proofs
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    )
    internal
    view
    returns (bool success)
    {
        require(in_proof.length == num_proofs * 8, "Invalid proofs length for a batch");
        require(proof_inputs.length % num_proofs == 0, "Invalid inputs length for a batch");
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length / num_proofs, "Invalid verification key");

        // strategy is to accumulate entropy separately for some proof elements
        // (accumulate only for G1, can't in G2) of the pairing equation, as well as input verification key,
        // postpone scalar multiplication as much as possible and check only one equation
        // by using 3 + num_proofs pairings only plus 2*num_proofs + (num_inputs+1) + 1 scalar multiplications compared to naive
        // 4*num_proofs pairings and num_proofs*(num_inputs+1) scalar multiplications

        bool valid;
        uint256[] memory proofsAandC;
        uint256[] memory inputAccumulators;
        (valid, proofsAandC, inputAccumulators) = accumulate(in_proof, proof_inputs, num_proofs);
        if (!valid) {
            return false;
        }

        uint256[4] memory finalVksAlphaX;
        (valid, finalVksAlphaX) = prepareBatches(in_vk, vk_gammaABC, inputAccumulators);
        if (!valid) {
            return false;
        }

        uint256[] memory inputs = new uint256[](6*num_proofs + 18);
        // first num_proofs pairings e(ProofA, ProofB)
        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            inputs[proofNumber*6] = proofsAandC[proofNumber*2];
            inputs[proofNumber*6 + 1] = proofsAandC[proofNumber*2 + 1];
            inputs[proofNumber*6 + 2] = in_proof[proofNumber*8 + 2];
            inputs[proofNumber*6 + 3] = in_proof[proofNumber*8 + 3];
            inputs[proofNumber*6 + 4] = in_proof[proofNumber*8 + 4];
            inputs[proofNumber*6 + 5] = in_proof[proofNumber*8 + 5];
        }

        // second pairing e(-finalVKaplha, vk.beta)
        inputs[num_proofs*6] = finalVksAlphaX[0];
        inputs[num_proofs*6 + 1] = NegateY(finalVksAlphaX[1]);
        inputs[num_proofs*6 + 2] = in_vk[2];
        inputs[num_proofs*6 + 3] = in_vk[3];
        inputs[num_proofs*6 + 4] = in_vk[4];
        inputs[num_proofs*6 + 5] = in_vk[5];

        // third pairing e(-finalVKx, vk.gamma)
        inputs[num_proofs*6 + 6] = finalVksAlphaX[2];
        inputs[num_proofs*6 + 7] = NegateY(finalVksAlphaX[3]);
        inputs[num_proofs*6 + 8] = in_vk[6];
        inputs[num_proofs*6 + 9] = in_vk[7];
        inputs[num_proofs*6 + 10] = in_vk[8];
        inputs[num_proofs*6 + 11] = in_vk[9];

        // fourth pairing e(-proof.C, finalVKdelta)
        inputs[num_proofs*6 + 12] = proofsAandC[num_proofs*2];
        inputs[num_proofs*6 + 13] = NegateY(proofsAandC[num_proofs*2 + 1]);
        inputs[num_proofs*6 + 14] = in_vk[10];
        inputs[num_proofs*6 + 15] = in_vk[11];
        inputs[num_proofs*6 + 16] = in_vk[12];
        inputs[num_proofs*6 + 17] = in_vk[13];

        uint256 inputsLength = inputs.length * 32;
        uint[1] memory out;
        require(inputsLength % 192 == 0, "Inputs length should be multiple of 192 bytes");

        assembly {
            success := staticcall(sub(gas, 2000), 8, add(inputs, 0x20), inputsLength, out, 0x20)
        }
        return success && out[0] == 1;
    }
}


/// @title IBlockVerifier
/// @author Brecht Devos - <brecht@loopring.org>
contract IBlockVerifier
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        bool           onchainDataAvailability,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external;

    /// @dev Disables the use of the specified circuit.
    ///      This will stop NEW blocks from using the given circuit, blocks that were already committed
    ///      can still be verified.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external;

    /// @dev Verify blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block See @BlockType
    /// @param onchainDataAvailability True if the block expects onchain
    ///        data availability data as public input, false otherwise
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool);
}

/// @title ILoopring
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopring is Claimable, ReentrancyGuard
{
    address public protocolRegistry;
    address public lrcAddress;
    uint    public exchangeCreationCostLRC;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    /// @dev Initialize and register an exchange.
    ///      This function should only be callabled by the protocolRegistry contract.
    ///      Also note that this function can only be called once per exchange instance.
    /// @param  exchangeAddress The address of the exchange to initialize and register.
    /// @param  exchangeId The unique exchange id.
    /// @param  owner The owner of the exchange.
    /// @param  operator The operator of the exchange.
    /// @param  onchainDataAvailability True if "Data Availability" is turned on for this
    ///         exchange. Note that this value can not be changed once the exchange is initialized.
    /// @return exchangeId The id of the exchange.
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

/// @title ILoopringV3
/// @author Brecht Devos - <brecht@loopring.org>
/// @author Daniel Wang  - <daniel@loopring.org>
contract ILoopringV3 is ILoopring
{
    // == Events ==

    event ExchangeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event ExchangeStakeBurned(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeDeposited(
        uint    indexed exchangeId,
        uint            amount
    );

    event ProtocolFeeStakeWithdrawn(
        uint    indexed exchangeId,
        uint            amount
    );

    event SettingsUpdated(
        uint            time
    );

    // == Public Variables ==
    struct Exchange
    {
        address exchangeAddress;
        uint    exchangeStake;
        uint    protocolFeeStake;
    }

    mapping (uint => Exchange) internal exchanges;

    uint    public totalStake;

    address public wethAddress;
    address public exchangeDeployerAddress;
    address public blockVerifierAddress;
    address public downtimeCostCalculator;
    uint    public maxWithdrawalFee;
    uint    public withdrawalFineLRC;
    uint    public tokenRegistrationFeeLRCBase;
    uint    public tokenRegistrationFeeLRCDelta;
    uint    public minExchangeStakeWithDataAvailability;
    uint    public minExchangeStakeWithoutDataAvailability;
    uint    public revertFineLRC;
    uint8   public minProtocolTakerFeeBips;
    uint8   public maxProtocolTakerFeeBips;
    uint8   public minProtocolMakerFeeBips;
    uint8   public maxProtocolMakerFeeBips;
    uint    public targetProtocolTakerFeeStake;
    uint    public targetProtocolMakerFeeStake;

    address payable public protocolFeeVault;

    // == Public Functions ==
    /// @dev Update the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        address _blockVerifierAddress,       // address(0) not allowed
        address _downtimeCostCalculator,     // address(0) allowed
        uint    _exchangeCreationCostLRC,
        uint    _maxWithdrawalFee,
        uint    _tokenRegistrationFeeLRCBase,
        uint    _tokenRegistrationFeeLRCDelta,
        uint    _minExchangeStakeWithDataAvailability,
        uint    _minExchangeStakeWithoutDataAvailability,
        uint    _revertFineLRC,
        uint    _withdrawalFineLRC
        )
        external;

    /// @dev Update the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _minProtocolTakerFeeBips,
        uint8 _maxProtocolTakerFeeBips,
        uint8 _minProtocolMakerFeeBips,
        uint8 _maxProtocolMakerFeeBips,
        uint  _targetProtocolTakerFeeStake,
        uint  _targetProtocolMakerFeeStake
        )
        external;

    /// @dev Returns whether the Exchange has staked enough to commit blocks
    ///      Exchanges with on-chain data-availaiblity need to stake at least
    ///      minExchangeStakeWithDataAvailability, exchanges without
    ///      data-availability need to stake at least
    ///      minExchangeStakeWithoutDataAvailability.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return True if the exchange has staked enough, else false
    function canExchangeCommitBlocks(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (bool);

    /// @dev Get the amount of staked LRC for an exchange.
    /// @param exchangeId The id of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        uint exchangeId
        )
        public
        view
        returns (uint stakedLRC);

    /// @dev Burn a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint exchangeId,
        uint amount
        )
        external
        returns (uint burnedLRC);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return stakedLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        uint    exchangeId,
        address recipient,
        uint    requestedAmount
        )
        external
        returns (uint amount);

    /// @dev Stake more LRC for an exchange.
    /// @param  exchangeId The id of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositProtocolFeeStake(
        uint exchangeId,
        uint amountLRC
        )
        external
        returns (uint stakedLRC);

    /// @dev Withdraw a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  exchangeId The id of the exchange
    /// @param  recipient The address to receive LRC
    /// @param  amount The amount of LRC to withdraw
    function withdrawProtocolFeeStake(
        uint    exchangeId,
        address recipient,
        uint    amount
        )
        external;

    /// @dev Get the protocol fee values for an exchange.
    /// @param exchangeId The id of the exchange
    /// @param onchainDataAvailability True if the exchange has on-chain
    ///        data-availability, else false
    /// @return takerFeeBips The protocol taker fee
    /// @return makerFeeBips The protocol maker fee
    function getProtocolFeeValues(
        uint exchangeId,
        bool onchainDataAvailability
        )
        external
        view
        returns (
            uint8 takerFeeBips,
            uint8 makerFeeBips
        );

    /// @dev Returns the exchange's protocol fee stake.
    /// @param  exchangeId The exchange's id.
    /// @return protocolFeeStake The exchange's protocol fee stake.
    function getProtocolFeeStake(
        uint exchangeId
        )
        external
        view
        returns (uint protocolFeeStake);
}

/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <daniel@loopring.org>
/// @author Brecht Devos - <brecht@loopring.org>
library ExchangeData
{
    // -- Enums --
    enum BlockType
    {
        RING_SETTLEMENT,
        DEPOSIT,
        ONCHAIN_WITHDRAWAL,
        OFFCHAIN_WITHDRAWAL,
        ORDER_CANCELLATION,
        TRANSFER
    }

    enum BlockState
    {
        // This value should never be seen onchain, but we want to reserve 0 so the
        // relayer can use this as the default for new blocks.
        NEW,            // = 0

        // The default state when a new block is included onchain.
        COMMITTED,      // = 1

        // A valid ZK proof has been submitted for this block.
        // The genesis block is VERIFIED by default.
        VERIFIED        // = 2
    }

    // -- Structs --
    struct Account
    {
        address owner;

        // pubKeyX and pubKeyY put together is the EdDSA public trading key. Users or their
        // wallet software are supposed to manage the corresponding private key for signing
        // orders and offchain requests.
        //
        // We use EdDSA because it is more circuit friendly than ECDSA. In later versions
        // we may switch back to ECDSA, then we will not need such a dedicated tradig key-pair.
        //
        // We split the public key into two uint to make it more circuit friendly.
        uint    pubKeyX;
        uint    pubKeyY;
    }

    struct Token
    {
        address token;
        bool    depositDisabled;
    }

    struct ProtocolFeeData
    {
        uint32 timestamp;
        uint8 takerFeeBips;
        uint8 makerFeeBips;
        uint8 previousTakerFeeBips;
        uint8 previousMakerFeeBips;
    }

    // This is the (virtual) block an operator needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        // The merkle root of the offchain data stored in a merkle tree. The merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;

        // The hash of all the public data sent in commitBlock. Committing a block
        // is decoupled from the verification of a block, but we don't want to send
        // the (often) large amount of data (certainly with onchain data availability) again
        // when verifying the proof, so we hash all that data onchain in commitBlock so that we
        // can use it in verifyBlock to verify the block. This also makes the verification cheaper
        // onchain because we only have this single public input.
        bytes32 publicDataHash;

        // The current state of the block. See @BlockState for more information.
        BlockState state;

        // The type of the block (i.e. what kind of requests were processed).
        // See @BlockType for more information.
        BlockType blockType;

        // The number of requests processed in the block. Only a limited number of permutations
        // are available for each block type (because each will need a different circuit
        // and thus different verification key onchain). Use IBlockVerifier.canVerify to find out if
        // the block is supported.
        uint16 blockSize;

        // The block version (i.e. what circuit version needs to be used to verify the block).
        uint8  blockVersion;

        // The time the block was created.
        uint32 timestamp;

        // The number of onchain deposit requests that have been processed
        // up to and including this block.
        uint32 numDepositRequestsCommitted;

        // The number of onchain withdrawal requests that have been processed
        // up to and including this block.
        uint32 numWithdrawalRequestsCommitted;

        // Stores whether the fee earned by the operator for processing onchain requests
        // is withdrawn or not.
        bool   blockFeeWithdrawn;

        // Number of withdrawals distributed using `distributeWithdrawals`
        uint16 numWithdrawalsDistributed;

        // The approved withdrawal data. Needs to be stored onchain so this data is available
        // once the block is finalized and the funds can be withdrawn using the info stored
        // in this data.
        // For every withdrawal (there are 'blockSize' withdrawals),
        // stored sequentially after each other:
        //    - Token ID: 1 bytes
        //    - Account ID: 2,5 bytes
        //    - Amount: 3,5 bytes
        bytes  withdrawals;
    }

    // Represents the post-state of an onchain deposit/withdrawal request. We can visualize
    // a deposit request-chain and a withdrawal request-chain, each of which is
    // composed of such Request objects. Please refer to the design doc for more details.
    struct Request
    {
        bytes32 accumulatedHash;
        uint    accumulatedFee;
        uint32  timestamp;
    }

    // Represents an onchain deposit request.  `tokenID` being `0x0` means depositing Ether.
    struct Deposit
    {
        uint24 accountID;
        uint16 tokenID;
        uint96 amount;
    }

    function SNARK_SCALAR_FIELD() internal pure returns (uint) {
        // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function MAX_PROOF_GENERATION_TIME_IN_SECONDS() internal pure returns (uint32) { return 1 hours; }
    function MAX_GAP_BETWEEN_FINALIZED_AND_VERIFIED_BLOCKS() internal pure returns (uint32) { return 2500; }
    function MAX_OPEN_DEPOSIT_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_OPEN_WITHDRAWAL_REQUESTS() internal pure returns (uint16) { return 1024; }
    function MAX_AGE_UNFINALIZED_BLOCK_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_AGE_REQUEST_UNTIL_FORCED() internal pure returns (uint32) { return 15 minutes; }
    function MAX_AGE_REQUEST_UNTIL_WITHDRAW_MODE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_BASE() internal pure returns (uint32) { return 1 days; }
    function MAX_TIME_IN_SHUTDOWN_DELTA() internal pure returns (uint32) { return 15 seconds; }
    function TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS() internal pure returns (uint32) { return 10 minutes; }
    function MAX_NUM_TOKENS() internal pure returns (uint) { return 2 ** 8; }
    function MAX_NUM_ACCOUNTS() internal pure returns (uint) { return 2 ** 20 - 1; }
    function MAX_TIME_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 2 hours; }
    function FEE_BLOCK_FINE_START_TIME() internal pure returns (uint32) { return 5 minutes; }
    function FEE_BLOCK_FINE_MAX_DURATION() internal pure returns (uint32) { return 30 minutes; }
    function MIN_GAS_TO_DISTRIBUTE_WITHDRAWALS() internal pure returns (uint32) { return 60000; }
    function MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED() internal pure returns (uint32) { return 1 days; }
    function GAS_LIMIT_SEND_TOKENS() internal pure returns (uint32) { return 30000; }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint    id;
        uint    exchangeCreationTimestamp;
        address payable operator; // The only address that can submit new blocks.
        bool    onchainDataAvailability;

        ILoopringV3    loopring;
        IBlockVerifier blockVerifier;

        address lrcAddress;

        uint    totalTimeInMaintenanceSeconds;
        uint    numDowntimeMinutes;
        uint    downtimeStart;

        address addressWhitelist;
        uint    accountCreationFeeETH;
        uint    accountUpdateFeeETH;
        uint    depositFeeETH;
        uint    withdrawalFeeETH;

        Block[]     blocks;
        Token[]     tokens;
        Account[]   accounts;
        Deposit[]   deposits;
        Request[]   depositChain;
        Request[]   withdrawalChain;

        // A map from the account owner to accountID + 1
        mapping (address => uint24) ownerToAccountId;
        mapping (address => uint16) tokenToTokenId;

        // A map from an account owner to a token to if the balance is withdrawn
        mapping (address => mapping (address => bool)) withdrawnInWithdrawMode;

        // A map from token address to their accumulated balances
        mapping (address => uint) tokenBalances;

        // A block's state will become FINALIZED when and only when this block is VERIFIED
        // and all previous blocks in the chain have become FINALIZED.
        // The genesis block is FINALIZED by default.
        uint numBlocksFinalized;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        // Time when the exchange was shutdown
        uint shutdownStartTime;
    }
}

/// @title An Implementation of IBlockVerifier.
/// @author Brecht Devos - <brecht@loopring.org>
contract BlockVerifier is Claimable, ReentrancyGuard, IBlockVerifier
{
    struct Circuit
    {
        bool registered;
        bool enabled;
        uint[18] verificationKey;
    }

    mapping (bool => mapping (uint8 => mapping (uint16 => mapping (uint8 => Circuit)))) public circuits;

    constructor() Claimable() public {}

    function registerCircuit(
        uint8    blockType,
        bool     onchainDataAvailability,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        nonReentrant
        onlyOwner
    {
        bool dataAvailability = needsDataAvailability(blockType, onchainDataAvailability);
        require(dataAvailability == onchainDataAvailability, "NO_DATA_AVAILABILITY_NEEDED");
        Circuit storage circuit = circuits[onchainDataAvailability][blockType][blockSize][blockVersion];
        require(circuit.registered == false, "ALREADY_REGISTERED");

        for (uint i = 0; i < 18; i++) {
            circuit.verificationKey[i] = vk[i];
        }
        circuit.registered = true;
        circuit.enabled = true;

        emit CircuitRegistered(
            blockType,
            onchainDataAvailability,
            blockSize,
            blockVersion
        );
    }

    function disableCircuit(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        nonReentrant
        onlyOwner
    {
        Circuit storage circuit = circuits[onchainDataAvailability][blockType][blockSize][blockVersion];
        require(circuit.registered == true, "NOT_REGISTERED");
        require(circuit.enabled == true, "ALREADY_DISABLED");

        circuit.enabled = false;

        emit CircuitDisabled(
            blockType,
            onchainDataAvailability,
            blockSize,
            blockVersion
        );
    }

    function verifyProofs(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        view
        returns (bool)
    {
        bool dataAvailability = needsDataAvailability(blockType, onchainDataAvailability);
        Circuit storage circuit = circuits[dataAvailability][blockType][blockSize][blockVersion];
        require(circuit.registered == true, "NOT_REGISTERED");

        uint[18] storage vk = circuit.verificationKey;
        uint[14] memory _vk = [
            vk[0], vk[1], vk[2], vk[3], vk[4], vk[5], vk[6],
            vk[7], vk[8], vk[9], vk[10], vk[11], vk[12], vk[13]
        ];
        uint[4] memory _vk_gammaABC = [vk[14], vk[15], vk[16], vk[17]];

        if (publicInputs.length == 1) {
            return Verifier.Verify(_vk, _vk_gammaABC, proofs, publicInputs);
        } else {
            return BatchVerifier.BatchVerify(
                _vk,
                _vk_gammaABC,
                proofs,
                publicInputs,
                publicInputs.length
            );
        }
    }

    function isCircuitRegistered(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool)
    {
        bool dataAvailability = needsDataAvailability(blockType, onchainDataAvailability);
        return circuits[dataAvailability][blockType][blockSize][blockVersion].registered;
    }

    function isCircuitEnabled(
        uint8  blockType,
        bool   onchainDataAvailability,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        view
        returns (bool)
    {
        bool dataAvailability = needsDataAvailability(blockType, onchainDataAvailability);
        return circuits[dataAvailability][blockType][blockSize][blockVersion].enabled;
    }

    function needsDataAvailability(
        uint8 blockType,
        bool  onchainDataAvailability
        )
        internal
        pure
        returns (bool)
    {
        // On-chain requests never need data-availability
        return (
            (blockType == uint(ExchangeData.BlockType.DEPOSIT)) ||
            (blockType == uint(ExchangeData.BlockType.ONCHAIN_WITHDRAWAL))
            ? false : onchainDataAvailability
        );
    }
}
