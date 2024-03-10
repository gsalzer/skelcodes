// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-vault/contracts/interfaces/IVault.sol";
import "@balancer-labs/v2-vault/contracts/interfaces/IBasePool.sol";
import "@balancer-labs/v2-pool-weighted/contracts/BaseWeightedPool.sol";

import "./PoolTokenCache.sol";
import "./interfaces/IDistributorCallback.sol";

contract Exiter is PoolTokenCache, IDistributorCallback {
    constructor(IVault _vault) PoolTokenCache(_vault) {
        // solhint-disable-previous-line no-empty-blocks
    }

    struct CallbackParams {
        address[] pools;
        address payable recipient;
    }

    /**
     * @notice Exits specified pool with all bpt
     * @param callbackData are the encoded function arguments:
     * recipient - the recipient of the pool tokens
     * pools - The pools to exit from (addresses)
     */
    function distributorCallback(bytes calldata callbackData) external override {
        CallbackParams memory params = abi.decode(callbackData, (CallbackParams));

        for (uint256 p; p < params.pools.length; p++) {
            address poolAddress = params.pools[p];

            IBasePool poolContract = IBasePool(poolAddress);
            bytes32 poolId = poolContract.getPoolId();
            ensurePoolTokenSetSaved(poolId);

            IERC20 pool = IERC20(poolAddress);
            _exitPool(pool, poolId, params.recipient);
        }
    }

    /**
     * @notice Exits the pool
     * Exiting to a single token would look like:
     * bytes memory userData = abi.encode(
     * BaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
     * bptBalance,
     * tokenIndexOut
     * );
     */
    function _exitPool(
        IERC20 pool,
        bytes32 poolId,
        address payable recipient
    ) internal {
        IAsset[] memory assets = _getAssets(poolId);
        uint256[] memory minAmountsOut = new uint256[](assets.length);

        uint256 bptAmountIn = pool.balanceOf(address(this));

        bytes memory userData = abi.encode(BaseWeightedPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptAmountIn);
        bool toInternalBalance = false;

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            assets,
            minAmountsOut,
            userData,
            toInternalBalance
        );
        vault.exitPool(poolId, address(this), recipient, request);
    }
}

