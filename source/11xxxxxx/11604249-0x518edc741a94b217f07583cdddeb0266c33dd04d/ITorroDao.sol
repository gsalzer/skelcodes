// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title DAO for proposals, voting and execution.
/// @notice Interface for creation, voting and execution of proposals.
interface ITorroDao {

  // Enums.

  /// @notice Enum of available proposal functions.
  enum DaoFunction {
    BUY,
    SELL,
    ADD_LIQUIDITY,
    REMOVE_LIQUIDITY,
    ADD_ADMIN,
    REMOVE_ADMIN,
    INVEST,
    WITHDRAW,
    BURN,
    SET_SPEND_PCT,
    SET_MIN_PCT,
    SET_QUICK_MIN_PCT,
    SET_MIN_HOURS,
    SET_MIN_VOTES,
    SET_FREE_PROPOSAL_DAYS,
    SET_BUY_LOCK_PER_ETH
  }

  // Initializer.
  
  /// @notice Initializer for DAO clones.
  /// @param torroToken_ main torro token address.
  /// @param governingToken_ torro token clone that's governing this dao.
  /// @param factory_ torro factory address.
  /// @param creator_ creator of cloned DAO.
  /// @param maxCost_ maximum cost of all governing tokens for cloned DAO.
  /// @param executeMinPct_ minimum percentage of votes needed for proposal execution.
  /// @param votingMinHours_ minimum lifetime of proposal before it closes.
  /// @param isPublic_ whether cloned DAO has public visibility.
  /// @param hasAdmins_ whether cloned DAO has admins, otherwise all stakers are treated as admins.
  function initializeCustom(
    address torroToken_,
    address governingToken_,
    address factory_,
    address creator_,
    uint256 maxCost_,
    uint256 executeMinPct_,
    uint256 votingMinHours_,
    bool isPublic_,
    bool hasAdmins_
  ) external;

  // Public calls.

  /// @notice Address of DAO creator.
  /// @return DAO creator address.
  function daoCreator() external view returns (address);

  /// @notice Amount of tokens needed for a single vote.
  /// @return uint256 token amount.
  function voteWeight() external view returns (uint256);

  /// @notice Amount of votes that holder has.
  /// @param sender_ address of the holder.
  /// @return number of votes.
  function votesOf(address sender_) external view returns (uint256);

  /// @notice Address of the governing token.
  /// @return address of the governing token.
  function tokenAddress() external view returns (address);

  /// @notice Saved addresses of tokens that DAO is holding.
  /// @return array of holdings addresses.
  function holdings() external view returns (address[] memory);

  /// @notice Saved addresses of liquidity tokens that DAO is holding.
  /// @return array of liquidity addresses.
  function liquidities() external view returns (address[] memory);

  /// @notice Calculates address of liquidity token from ERC-20 token address.
  /// @param token_ token address to calculate liquidity address from.
  /// @return address of liquidity token.
  function liquidityToken(address token_) external view returns (address);

  /// @notice Gets tokens and liquidity token addresses of DAO's liquidity holdings.
  /// @return Arrays of tokens and liquidity tokens, should have the same length.
  function liquidityHoldings() external view returns (address[] memory, address[] memory);

  /// @notice DAO admins.
  /// @return Array of admin addresses.
  function admins() external view returns (address[] memory);

  /// @notice DAO balance for specified token.
  /// @param token_ token address to get balance for.
  /// @return uint256 token balance.
  function tokenBalance(address token_) external view returns (uint256);

  /// @notice DAO balance for liquidity token.
  /// @param token_ token address to get liquidity balance for.
  /// @return uin256 token liquidity balance.
  function liquidityBalance(address token_) external view returns (uint256);

  /// @notice DAO ethereum balance.
  /// @return uint256 wei balance.
  function availableBalance() external view returns (uint256);

  /// @notice DAO WETH balance.
  /// @return uint256 wei balance.
  function availableWethBalance() external view returns (uint256);

  /// @notice Maximum cost for all tokens of cloned DAO.
  /// @return uint256 maximum cost in wei.
  function maxCost() external view returns (uint256);

  /// @notice Minimum percentage of votes needed to execute a proposal.
  /// @return uint256 minimum percentage of votes.
  function executeMinPct() external view returns (uint256);

  /// @notice Minimum percentage of votes needed for quick execution of proposal.
  /// @return uint256 minimum percentage of votes.
  function quickExecuteMinPct() external returns (uint256);

  /// @notice Minimum lifetime of proposal before it closes.
  /// @return uint256 minimum number of hours for proposal lifetime.
  function votingMinHours() external view returns (uint256);

  /// @notice Minimum votes a proposal needs to pass.
  /// @return uint256 minimum unique votes.
  function minProposalVotes() external view returns (uint256);

  /// @notice Maximum spend limit on BUY, WITHDRAW and INVEST proposals.
  /// @return uint256 maximum percentage of funds that can be spent.
  function spendMaxPct() external view returns (uint256);

  /// @notice Interval at which stakers can create free proposals.
  /// @return uint256 number of days between free proposals.
  function freeProposalDays() external view returns (uint256);

  /// @notice Next free proposal time for staker.
  /// @param sender_ address to check free proposal time for.
  /// @return uint256 unix time of next free proposal or 0 if not available.
  function nextFreeProposal(address sender_) external view returns (uint256);

  /// @notice Amount of tokens that BUY proposal creator has to lock per each ETH spent in a proposal.
  /// @return uint256 number for tokens per eth spent.
  function lockPerEth() external view returns (uint256);

  /// @notice Whether DAO is public or private.
  /// @return bool true if public.
  function isPublic() external view returns (bool);

  /// @notice Whether DAO has admins.
  /// @return bool true if DAO has admins.
  function hasAdmins() external view returns (bool);

  /// @notice Proposal ids of DAO.
  /// @return array of proposal ids.
  function getProposalIds() external view returns (uint256[] memory);

  /// @notice Gets proposal info for proposal id.
  /// @param id_ id of proposal to get info for.
  /// @return proposalAddress address for proposal execution.
  /// @return investTokenAddress secondary address for proposal execution, used for investment proposals if ICO and token addresses differ.
  /// @return daoFunction proposal type.
  /// @return amount proposal amount eth/token to use during execution.
  /// @return creator address of proposal creator.
  /// @return endLifetime epoch time when proposal voting ends.
  /// @return votesFor amount of votes for the proposal.
  /// @return votesAgainst amount of votes against the proposal.
  /// @return votes number of stakers that voted for the proposal.
  /// @return executed whether proposal has been executed or not.
  function getProposal(uint256 id_) external view returns (
    address proposalAddress,
    address investTokenAddress,
    DaoFunction daoFunction,
    uint256 amount,
    address creator,
    uint256 endLifetime,
    uint256 votesFor,
    uint256 votesAgainst,
    uint256 votes,
    bool executed
  );

  /// @notice Whether a holder is allowed to vote for a proposal.
  /// @param id_ proposal id to check whether holder is allowed to vote for.
  /// @param sender_ address of the holder.
  /// @return bool true if voting is allowed.
  function canVote(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is allowed to remove a proposal.
  /// @param id_ proposal id to check whether holder is allowed to remove.
  /// @param sender_ address of the holder.
  /// @return bool true if removal is allowed.
  function canRemove(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is allowed to execute a proposal.
  /// @param id_ proposal id to check whether holder is allowed to execute.
  /// @param sender_ address of the holder.
  /// @return bool true if execution is allowed.
  function canExecute(uint256 id_, address sender_) external view returns (bool);

  /// @notice Whether a holder is an admin.
  /// @param sender_ address of holder.
  /// @return bool true if holder is an admin (in DAO without admins all holders are treated as such).
  function isAdmin(address sender_) external view returns (bool);

  // Public transactions.

  /// @notice Saves new holdings addresses for DAO.
  /// @param tokens_ token addresses that DAO has holdings of.
  function addHoldingsAddresses(address[] calldata tokens_) external;

  /// @notice Saves new liquidity addresses for DAO.
  /// @param tokens_ token addresses that DAO has liquidities of.
  function addLiquidityAddresses(address[] calldata tokens_) external;

  /// @notice Creates new proposal.
  /// @param proposalAddress_ main address of the proposal, in investment proposals this is the address funds are sent to.
  /// @param investTokenAddress_ secondary address of the proposal, used in investment proposals to specify token address.
  /// @param daoFunction_ type of the proposal.
  /// @param amount_ amount of funds to use in the proposal.
  /// @param hoursLifetime_ voting lifetime of the proposal.
  function propose(address proposalAddress_, address investTokenAddress_, DaoFunction daoFunction_, uint256 amount_, uint256 hoursLifetime_) external;

  /// @notice Removes existing proposal.
  /// @param id_ id of proposal to remove.
  function unpropose(uint256 id_) external;

  /// @notice Cancels buy proposal.
  /// @param id_ buy proposal id to cancel.
  function cancelBuy(uint256 id_) external;

  /// @notice Voting for multiple proposals.
  /// @param ids_ ids of proposals to vote for.
  /// @param votes_ for or against votes for proposals.
  function vote(uint256[] calldata ids_, bool[] calldata votes_) external;

  /// @notice Executes a proposal.
  /// @param id_ id of proposal to be executed.
  function execute(uint256 id_) external;

  /// @notice Buying tokens for cloned DAO.
  function buy() external payable;

  /// @notice Sell tokens back to cloned DAO.
  /// @param amount_ amount of tokens to sell.
  function sell(uint256 amount_) external;

  // Owner transactions.

  /// @notice Sets factory address.
  /// @param factory_ address of TorroFactory.
  function setFactoryAddress(address factory_) external;

  /// @notice Sets vote weight divider.
  /// @param weight_ weight divider for a single vote.
  function setVoteWeightDivider(uint256 weight_) external;

  /// @notice Sets new address for router.
  /// @param router_ address for router.
  function setRouter(address router_) external;

  /// @notice Sets address of new token.
  /// @param token_ token address.
  /// @param torroToken_ address of main Torro DAO token.
  function setNewToken(address token_, address torroToken_) external;

  /// @notice Migrates balances of current DAO to a new DAO.
  /// @param newDao_ address of the new DAO to migrate to.
  function migrate(address newDao_) external;

}
