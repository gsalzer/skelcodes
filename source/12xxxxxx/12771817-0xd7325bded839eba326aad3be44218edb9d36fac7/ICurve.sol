// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

interface ICurveLINK {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 _dx,
        uint256 _min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory _min_amounts) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(uint256[2] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(uint256 _new_fee, uint256 _new_admin_fee) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function previous_balances(uint256 arg0) external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function owner() external view returns (address);

    function lp_token() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_owner() external view returns (address);
}

interface ILinkGauge {
    function decimals() external view returns (uint256);

    function integrate_checkpoint() external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);

    function claimable_tokens(address addr) external returns (uint256);

    function claimable_reward(address _addr, address _token) external returns (uint256);

    function claim_rewards() external;

    function claim_rewards(address _addr) external;

    function claim_historic_rewards(address[8] memory _reward_tokens) external;

    function claim_historic_rewards(address[8] memory _reward_tokens, address _addr) external;

    function kick(address addr) external;

    function set_approve_deposit(address addr, bool can_deposit) external;

    function deposit(uint256 _value) external;

    function deposit(uint256 _value, address _addr) external;

    function withdraw(uint256 _value) external;

    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function approve(address _spender, uint256 _value) external returns (bool);

    function increaseAllowance(address _spender, uint256 _added_value) external returns (bool);

    function decreaseAllowance(address _spender, uint256 _subtracted_value) external returns (bool);

    function set_rewards(
        address _reward_contract,
        bytes32 _sigs,
        address[8] memory _reward_tokens
    ) external;

    function set_killed(bool _is_killed) external;

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function minter() external view returns (address);

    function crv_token() external view returns (address);

    function lp_token() external view returns (address);

    function controller() external view returns (address);

    function voting_escrow() external view returns (address);

    function future_epoch_time() external view returns (uint256);

    function balanceOf(address arg0) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function approved_to_deposit(address arg0, address arg1) external view returns (bool);

    function working_balances(address arg0) external view returns (uint256);

    function working_supply() external view returns (uint256);

    function period() external view returns (int128);

    function period_timestamp(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply(uint256 arg0) external view returns (uint256);

    function integrate_inv_supply_of(address arg0) external view returns (uint256);

    function integrate_checkpoint_of(address arg0) external view returns (uint256);

    function integrate_fraction(address arg0) external view returns (uint256);

    function inflation_rate() external view returns (uint256);

    function reward_contract() external view returns (address);

    function reward_tokens(uint256 arg0) external view returns (address);

    function reward_integral(address arg0) external view returns (uint256);

    function reward_integral_for(address arg0, address arg1) external view returns (uint256);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function is_killed() external view returns (bool);
}

interface IveCurveVault {
    function CRV() external view returns (address);

    function DELEGATION_TYPEHASH() external view returns (bytes32);

    function DOMAINSEPARATOR() external view returns (bytes32);

    function DOMAIN_TYPEHASH() external view returns (bytes32);

    function LOCK() external view returns (address);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function acceptGovernance() external;

    function allowance(address account, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function bal() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function checkpoints(address, uint32) external view returns (uint32 fromBlock, uint256 votes);

    function claim() external;

    function claimFor(address recipient) external;

    function claimable(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function delegates(address) external view returns (address);

    function deposit(uint256 _amount) external;

    function depositAll() external;

    function feeDistribution() external view returns (address);

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governance() external view returns (address);

    function index() external view returns (uint256);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function numCheckpoints(address) external view returns (uint32);

    function pendingGovernance() external view returns (address);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function proxy() external view returns (address);

    function rewards() external view returns (address);

    function setFeeDistribution(address _feeDistribution) external;

    function setGovernance(address _governance) external;

    function setProxy(address _proxy) external;

    function supplyIndex(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function update() external;

    function updateFor(address recipient) external;
}

