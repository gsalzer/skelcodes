// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SP1Storage } from './SP1Storage.sol';

/**
 * @title SP1Roles
 * @author dYdX
 *
 * @dev Defines roles used in the StarkProxyV1 contract. The hierarchy and powers of each role
 *  are described below. Not all roles need to be used.
 *
 *  Overview:
 *
 *    During operation of this contract, funds will flow between the following three
 *    contracts:
 *
 *        LiquidityStaking <> StarkProxy <> StarkPerpetual
 *
 *    Actions which move fund from left to right are called “open” actions, whereas actions which
 *    move funds from right to left are called “close” actions.
 *
 *    Also note that the “forced” actions (forced trade and forced withdrawal) require special care
 *    since they directly impact the financial risk of positions held on the exchange.
 *
 *  Roles:
 *
 *    GUARDIAN_ROLE
 *      | -> May perform “close” actions as defined above, but “forced” actions can only be taken
 *      |    if the borrower has an outstanding debt balance.
 *      | -> May restrict “open” actions as defined above, except w.r.t. funds in excess of the
 *      |    borrowed balance.
 *      | -> May approve a token amount to be withdrawn externally by the WITHDRAWAL_OPERATOR_ROLE
 *      |    to an allowed address.
 *      |
 *      +-- VETO_GUARDIAN_ROLE
 *            -> May veto forced trade requests initiated by the owner, during the waiting period.
 *
 *    OWNER_ROLE
 *      | -> May add or remove allowed recipients who may receive excess funds.
 *      | -> May add or remove allowed STARK keys for use on the exchange.
 *      | -> May set ERC20 allowances on the LiquidityStakingV1 and StarkPerpetual contracts.
 *      | -> May call the “forced” actions: forcedWithdrawalRequest and forcedTradeRequest.
 *      |
 *      +-- DELEGATION_ADMIN_ROLE
 *            |
 *            +-- BORROWER_ROLE
 *            |     -> May call functions on LiquidityStakingV1: autoPayOrBorrow, borrow, repay,
 *            |        and repayDebt.
 *            |
 *            +-- EXCHANGE_OPERATOR_ROLE
 *            |     -> May call functions on StarkPerpetual: depositToExchange and
 *            |        withdrawFromExchange.
 *            |
 *            +-- WITHDRAWAL_OPERATOR_ROLE
 *                  -> May withdraw funds in excess of the borrowed balance to an allowed recipient.
 */
abstract contract SP1Roles is
  SP1Storage
{
  bytes32 public constant GUARDIAN_ROLE = keccak256('GUARDIAN_ROLE');
  bytes32 public constant VETO_GUARDIAN_ROLE = keccak256('VETO_GUARDIAN_ROLE');
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant DELEGATION_ADMIN_ROLE = keccak256('DELEGATION_ADMIN_ROLE');
  bytes32 public constant BORROWER_ROLE = keccak256('BORROWER_ROLE');
  bytes32 public constant EXCHANGE_OPERATOR_ROLE = keccak256('EXCHANGE_OPERATOR_ROLE');
  bytes32 public constant WITHDRAWAL_OPERATOR_ROLE = keccak256('WITHDRAWAL_OPERATOR_ROLE');

  function __SP1Roles_init(
    address guardian
  )
    internal
  {
    // Assign GUARDIAN_ROLE.
    _setupRole(GUARDIAN_ROLE, guardian);

    // Assign OWNER_ROLE and DELEGATION_ADMIN_ROLE to the sender.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(DELEGATION_ADMIN_ROLE, msg.sender);

    // Set admins for all roles. (Don't use the default admin role.)
    _setRoleAdmin(GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(VETO_GUARDIAN_ROLE, GUARDIAN_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(DELEGATION_ADMIN_ROLE, OWNER_ROLE);
    _setRoleAdmin(BORROWER_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(EXCHANGE_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
    _setRoleAdmin(WITHDRAWAL_OPERATOR_ROLE, DELEGATION_ADMIN_ROLE);
  }
}

