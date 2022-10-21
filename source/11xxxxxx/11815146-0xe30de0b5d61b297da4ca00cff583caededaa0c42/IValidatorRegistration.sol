// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/**
 * @title IValidatorRegistration
 * @dev Interface for ValidatorRegistration
 */
interface IValidatorRegistration {
  // Data structure to represent each Aventus Node
  struct Node {
    // Amount deposited in stake for a node
    uint stake;
    // Fees associated with a node for each month
    Fee[12] fees;
    // Amount of stake associated with any particular staker
    mapping (address => uint) stakerBalance;
  }

  // Data structure to represent each month's worth of fees for a node
  struct Fee {
    // Total fees remaining to be distributed
    uint balance;
    // Which stakers have already withdrawn their fees for the month
    mapping (address => bool) isWithdrawn;
  }

  /**
   * @dev Getter for the stake associated with a node
   * @param node the index of the node associated with the AVT
   */
  function getNodeStake(uint8 node) external view returns (uint);

  /**
   * @dev Getter for the staker balance associated with a node
   * @param node the index of the node associated with the AVT
   * @param staker the address of the staker for which the balance is retrieved
   */
  function getStakerBalance(uint8 node, address staker) external view returns (uint);

  /**
   * @dev deposit AVT tokens for staking.
   * @param amount number of AVT tokens to be deposited as stake for a node
   * @param node the index of the node to associate the AVT stake with
   */
  function depositStakeAndAgreeToTermsAndConditions(uint amount, uint8 node) external;

  /**
   * @dev withdraw AVT tokens from staking. Only active after the 12 month period, manually set by owner.
   * @param amount number of AVT tokens to be withdrawn from stake for a node
   * @param node the index of the node associated with the AVT stake
   */
  function withdrawStake(uint amount, uint8 node) external;

  /**
   * @dev deposit AVT fees associated with each node for each month. Anyone can deposit fees but likely will only be owner.
   * @param amount number of AVT tokens to be deposited as fees
   * @param node the index of the node having the fees deposited
   * @param month the month for which the fees are being deposited
   */
  function depositFees(uint amount, uint8 node, uint8 month) external;

  /**
   * @dev withdraw AVT fees associated with each node for each month for a particular staker.
   * @param _node the index of the node from which fees are being withdrawn
   * @param month the month for which the fees are being withdrawn
   */
  function withdrawFees(uint8 _node, uint8 month) external;

  /**
   * @dev Switch between (not) accepting withdrawals of stake.
   * Only owner can do this and will do so at the end of NUM_MONTHS to return stake.
   */
  function flipIsWithdrawStake() external;

  /**
   * @dev Remove the balance of AVT associated with a staker.
   * @param staker the address of the staker
   * @param _node the index of the node
   */
  function removeStaker(address staker, uint8 _node) external;

   /**
   * @dev Sends AVT associated with this contract to the dst address. Only owner can do this to get stake for nodes.
   * @param dst is the destination address where the stake should be sent
   */
  function drain(address dst) external;
}
