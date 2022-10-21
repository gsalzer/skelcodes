// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IAssetAllocation, IERC20} from "contracts/common/Imports.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

import {IStakedAave} from "./common/interfaces/IStakedAave.sol";
import {AaveBasePool} from "./common/AaveBasePool.sol";

contract StakedAaveZap is AaveBasePool {
    event WithdrawSucceeded(uint256 amount);
    event CooldownFromWithdrawFail(uint256 timestamp);

    constructor()
        public
        AaveBasePool(
            AAVE_ADDRESS, // underlyer
            STAKED_AAVE_ADDRESS // "pool"
        )
    {} // solhint-disable-line no-empty-blocks

    // solhint-disable-next-line no-empty-blocks
    function claim() external virtual override {
        IStakedAave stkAave = IStakedAave(POOL_ADDRESS);
        uint256 amount = stkAave.getTotalRewardsBalance(address(this));
        stkAave.claimRewards(address(this), amount);
    }

    function assetAllocations() public view override returns (string[] memory) {
        return new string[](0);
    }

    /// @dev track only unstaked AAVE
    function erc20Allocations() public view override returns (IERC20[] memory) {
        IERC20[] memory allocations = new IERC20[](1);
        allocations[0] = IERC20(UNDERLYER_ADDRESS);
        return allocations;
    }

    function _deposit(uint256 amount) internal override {
        IStakedAave(POOL_ADDRESS).stake(address(this), amount);
    }

    function _withdraw(uint256 amount) internal override {
        IStakedAave stkAave = IStakedAave(POOL_ADDRESS);
        try stkAave.redeem(address(this), amount) {
            emit WithdrawSucceeded(amount);
        } catch Error(string memory reason) {
            if (
                keccak256(bytes(reason)) ==
                keccak256(bytes("UNSTAKE_WINDOW_FINISHED"))
            ) {
                // Either there's never been a cooldown or it expired
                // and the unstake window also finished.
                stkAave.cooldown();
                emit CooldownFromWithdrawFail(block.timestamp); // solhint-disable-line not-rely-on-time
            } else if (
                keccak256(bytes(reason)) ==
                keccak256(bytes("INSUFFICIENT_COOLDOWN"))
            ) {
                // Still within the cooldown period; this is expected to
                // happen often, so we single this case out for better
                // understanding and possible future refactoring.
                revert(reason);
            } else {
                revert(reason);
            }
        } catch (bytes memory) {
            revert("STKAAVE_UNKNOWN_REASON");
        }
    }
}

