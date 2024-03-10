// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;


interface ILQTYToken {

    /**
     * @notice Function returns totoal LQTY token supply.
     * @return totalSupply
     */
    function totalSupply() external view returns (uint256);
  
    /**
     * @notice Function returns account's balance.
     * @param account the address of the user.
     * @return balance
     */
    function balanceOf(address account) external view returns (uint256);
  
    /**
     * @notice Function returns contract deployment start time.
     * @return deploymentStartTime
     */
    function getDeploymentStartTime() external view returns (uint256);
  
  
    /**
     * @notice Function returns the liquity token staking address.
     * @return lqtyStakingAddress
     */
    function lqtyStakingAddress() external view returns (address);
  
    /**
     * @notice Function returns the symbol of the token.
     * @return symbol
     */
    function symbol() external view returns (string memory);
  
    /**
     * @notice Function returns the name of the token.
     * @return name
     */
    function name() external view returns (string memory);
}
