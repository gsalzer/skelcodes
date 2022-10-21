// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/GachaState.sol";

contract XGachaState is GachaState {
    constructor() {}

    function x_stake(GachaState.Chip calldata chip) external {
        return super._stake(chip);
    }

    function x_refund(address sender,uint256[] calldata chipIndexes) external returns (uint256) {
        return super._refund(sender,chipIndexes);
    }

    function x_pick(uint256 randomness) external view returns (address) {
        return super._pick(randomness);
    }

    function x_reset() external {
        return super._reset();
    }

    function x_checkMaintainSegment(uint256 offset) external view returns (bool) {
        return super._checkMaintainSegment(offset);
    }

    function x_performMaintainSegment() external {
        return super._performMaintainSegment();
    }
}

