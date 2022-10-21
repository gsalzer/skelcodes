// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

import "./RealityModule.sol";
import "./interfaces/RealitioV3.sol";

contract RealityModuleERC20 is RealityModule {
    /// @param _owner Address of the owner
    /// @param _avatar Address of the avatar (e.g. a Safe)
    /// @param _target Address of the contract that will call exec function
    /// @param _oracle Address of the oracle (e.g. Realitio)
    /// @param timeout Timeout in seconds that should be required for the oracle
    /// @param cooldown Cooldown in seconds that should be required after a oracle provided answer
    /// @param expiration Duration that a positive answer of the oracle is valid in seconds (or 0 if valid forever)
    /// @param bond Minimum bond that is required for an answer to be accepted
    /// @param templateId ID of the template that should be used for proposal questions (see https://github.com/realitio/realitio-dapp#structuring-and-fetching-information)
    /// @param arbitrator Address of the arbitrator that will secure the oracle resolution
    /// @notice There need to be at least 60 seconds between end of cooldown and expiration
    constructor(
        address _owner,
        address _avatar,
        address _target,
        RealitioV3 _oracle,
        uint32 timeout,
        uint32 cooldown,
        uint32 expiration,
        uint256 bond,
        uint256 templateId,
        address arbitrator
    )
        RealityModule(
            _owner,
            _avatar,
            _target,
            _oracle,
            timeout,
            cooldown,
            expiration,
            bond,
            templateId,
            arbitrator
        )
    {}

    function askQuestion(string memory question, uint256 nonce)
        internal
        override
        returns (bytes32)
    {
        // Ask the question with a starting time of 0, so that it can be immediately answered
        return
            RealitioV3ERC20(address(oracle)).askQuestionWithMinBondERC20(
                template,
                question,
                questionArbitrator,
                questionTimeout,
                0,
                nonce,
                minimumBond,
                0
            );
    }
}

