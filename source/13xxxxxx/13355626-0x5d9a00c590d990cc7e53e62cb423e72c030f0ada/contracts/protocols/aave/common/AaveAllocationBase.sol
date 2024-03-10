// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IERC20} from "contracts/common/Imports.sol";
import {SafeMath} from "contracts/libraries/Imports.sol";

import {
    ILendingPool,
    DataTypes
} from "contracts/protocols/aave/common/interfaces/ILendingPool.sol";
import {ApyUnderlyerConstants} from "contracts/protocols/apy.sol";

/**
 * @title Periphery Contract for the Aave lending pool
 * @author APY.Finance
 * @notice This contract enables the APY.Finance system to retrieve the balance
 * of an underlyer of an Aave lending token. The balance is used as part
 * of the Chainlink computation of the deployed TVL.  The primary
 * `getUnderlyerBalance` function is invoked indirectly when a
 * Chainlink node calls `balanceOf` on the APYAssetAllocationRegistry.
 */
contract AaveAllocationBase {
    using SafeMath for uint256;

    /**
     * @notice Returns the balance of an underlying token represented by
     * an account's aToken balance
     * @dev aTokens represent the underlyer amount at par (1-1), growing with interest.
     * @param underlyer address of the underlying asset of the aToken
     * @param pool Aave lending pool
     * @return balance
     */
    function getUnderlyerBalance(
        address account,
        ILendingPool pool,
        address underlyer
    ) public view returns (uint256) {
        require(account != address(0), "INVALID_ACCOUNT");
        require(address(pool) != address(0), "INVALID_POOL");
        require(underlyer != address(0), "INVALID_UNDERLYER");

        DataTypes.ReserveData memory reserve = pool.getReserveData(underlyer);
        address aToken = reserve.aTokenAddress;
        // No unwrapping of aTokens are needed, as `balanceOf`
        // automagically reflects the accrued interest and
        // aTokens convert 1:1 to the underlyer.
        return IERC20(aToken).balanceOf(account);
    }
}

