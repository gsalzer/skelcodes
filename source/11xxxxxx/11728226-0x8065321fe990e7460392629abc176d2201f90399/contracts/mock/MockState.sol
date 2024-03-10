/*
    Copyright 2020 Empty Set Squad <emptysetsquad@protonmail.com>

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

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

import "../dao/Setters.sol";

contract MockState is Setters {
    uint256 internal _blockTimestamp;

    constructor () public {
        _blockTimestamp = block.timestamp;
    }

    /**
     * Global
     */

    function incrementTotalBondedE(uint256 amount) external {
        super.incrementTotalBonded(amount);
    }

    function decrementTotalBondedE(uint256 amount, string calldata reason) external {
        super.decrementTotalBonded(amount, reason);
    }

    /**
     * Account
     */

    function incrementBalanceOfE(address account, uint256 amount) external {
        super.incrementBalanceOf(account, amount);
    }

    function decrementBalanceOfE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOf(account, amount, reason);
    }

    function incrementBalanceOfStagedE(address account, uint256 amount) external {
        super.incrementBalanceOfStaged(account, amount);
    }

    function decrementBalanceOfStagedE(address account, uint256 amount, string calldata reason) external {
        super.decrementBalanceOfStaged(account, amount, reason);
    }

    function unfreezeE(address account) external {
        super.unfreeze(account);
    }

    /**
     * Epoch
     */

    function setEpochParamsE(uint256 start, uint256 period) external {
        _state.epoch.start = start;
        _state.epoch.period = period;
    }

    function incrementEpochE() external {
        super.incrementEpoch();
    }

    function snapshotTotalBondedE() external {
        super.snapshotTotalBonded();
    }

    /**
     * Governance
     */

    function createCandidateE(address candidate, uint256 period) external {
        super.createCandidate(candidate, period);
    }

    function recordVoteE(address account, address candidate, Candidate.Vote vote) external {
        super.recordVote(account, candidate, vote);
    }

    function incrementApproveForE(address candidate, uint256 amount) external {
        super.incrementApproveFor(candidate, amount);
    }

    function decrementApproveForE(address candidate, uint256 amount, string calldata reason) external {
        super.decrementApproveFor(candidate, amount, reason);
    }

    function incrementRejectForE(address candidate, uint256 amount) external {
        super.incrementRejectFor(candidate, amount);
    }

    function decrementRejectForE(address candidate, uint256 amount, string calldata reason) external {
        super.decrementRejectFor(candidate, amount, reason);
    }

    function placeLockE(address account, address candidate) external {
        super.placeLock(account, candidate);
    }

    function initializedE(address candidate) external {
        super.initialized(candidate);
    }

    /**
     * Mock
     */

    function setBlockTimestamp(uint256 timestamp) external {
        _blockTimestamp = timestamp;
    }

    function blockTimestamp() internal view returns (uint256) {
        return _blockTimestamp;
    }

    /**
     * 
     */
     
    function setPoolGov(address poolGov) external {
        _state.provider.poolGov = poolGov;
    }
}

