// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILQTYStaking {
      
    /**
     * @notice function returns the staking amount of the address.
     * @param account The address of the account.
     * @return amount The amount of stake.
     */
    function stakes(address account) external view returns (uint256);

    /**
     * @notice function returns total staked lqty token amount.
     * @return total The amount of staked lqyt token amount.
     */
    function totalLQTYStaked() external view returns (uint256);
}
