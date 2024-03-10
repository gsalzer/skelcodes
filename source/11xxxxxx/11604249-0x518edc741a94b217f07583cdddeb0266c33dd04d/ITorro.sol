// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.6.6;

/// @title Interface for ERC-20 Torro governing token.
/// @notice ERC-20 token.
interface ITorro {

  // Initializer.

  /// @notice Initializes governing token.
  /// @param dao_ address of cloned DAO.
  /// @param factory_ address of factory.
  /// @param supply_ total supply of tokens.
  function initializeCustom(address dao_, address factory_, uint256 supply_) external;

  // Public calls.

  /// @notice Token's name.
  /// @return string name of the token.
  function name() external view returns (string memory);

  /// @notice Token's symbol.
  /// @return string symbol of the token.
  function symbol() external view returns (string memory);

  /// @notice Token's decimals.
  /// @return uint8 demials of the token.
  function decimals() external pure returns (uint8);

  /// @notice Token's total supply.
  /// @return uint256 total supply of the token.
  function totalSupply() external view returns (uint256);

  /// @notice Count of token holders.
  /// @return uint256 number of token holders.
  function holdersCount() external view returns (uint256);

  /// @notice All token holders.
  /// @return array of addresses of token holders.
  function holders() external view returns (address[] memory);

  /// @notice Available balance for address.
  /// @param sender_ address to get available balance for.
  /// @return uint256 amount of tokens available for given address.
  function balanceOf(address sender_) external view returns (uint256);

  /// @notice Staked balance for address.
  /// @param sender_ address to get staked balance for.
  /// @return uint256 amount of staked tokens for given address.
  function stakedOf(address sender_) external view returns (uint256);

  /// @notice Total balance for address = available + staked.
  /// @param sender_ address to get total balance for.
  /// @return uint256 total amount of tokens for given address.
  function totalOf(address sender_) external view returns (uint256);

  /// @notice Locked staked balance for address
  /// @param sender_ address to get locked staked balance for.
  /// @return uint256 amount of locked staked tokens for given address.
  function lockedOf(address sender_) external view returns (uint256);

  /// @notice Spending allowance.
  /// @param owner_ token owner address.
  /// @param spender_ token spender address.
  /// @return uint256 amount of owner's tokens that spender can use.
  function allowance(address owner_, address spender_) external view returns (uint256);

  /// @notice Unstaked supply of token.
  /// @return uint256 amount of tokens in circulation that are not staked.
  function unstakedSupply() external view returns (uint256);

  /// @notice Staked supply of token.
  /// @return uint256 amount of tokens in circulation that are staked.
  function stakedSupply() external view returns (uint256);

  // Public transactions.

  /// @notice Transfer tokens to recipient.
  /// @param recipient_ address of tokens' recipient.
  /// @param amount_ amount of tokens to transfer.
  /// @return bool true if successful.
  function transfer(address recipient_, uint256 amount_) external returns (bool);

  /// @notice Approve spender to spend an allowance.
  /// @param spender_ address that will be allowed to spend specified amount of tokens.
  /// @param amount_ amount of tokens that spender can spend.
  /// @return bool true if successful.
  function approve(address spender_, uint256 amount_) external returns (bool);

  /// @notice Approves DAO to spend tokens.
  /// @param owner_ address whose tokens DAO can spend.
  /// @param amount_ amount of tokens that DAO can spend.
  /// @return bool true if successful.
  function approveDao(address owner_, uint256 amount_) external returns (bool);

  /// @notice Locks account's staked tokens.
  /// @param owner_ address whose tokens should be locked.
  /// @param amount_ amount of tokens to lock.
  /// @param id_ lock id.
  function lockStakesDao(address owner_, uint256 amount_, uint256 id_) external;

  /// @notice Unlocks account's staked tokens.
  /// @param owner_ address whose tokens should be unlocked.
  /// @param id_ unlock id.
  function unlockStakesDao(address owner_, uint256 id_) external;

  /// @notice Transfers tokens from owner to recipient by approved spender.
  /// @param owner_ address of tokens' owner whose tokens will be spent.
  /// @param recipient_ address of recipient that will recieve tokens.
  /// @param amount_ amount of tokens to be spent.
  /// @return bool true if successful.
  function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool);

  /// @notice Increases allowance for given spender.
  /// @param spender_ spender to increase allowance for.
  /// @param addedValue_ extra amount that spender can spend.
  /// @return bool true if successful.
  function increaseAllowance(address spender_, uint256 addedValue_) external returns (bool);

  /// @notice Decreases allowance for given spender.
  /// @param spender_ spender to decrease allowance for.
  /// @param subtractedValue_ removed amount that spender can spend.
  /// @return bool true if successful.
  function decreaseAllowance(address spender_, uint256 subtractedValue_) external returns (bool);

  /// @notice Stake tokens.
  /// @param amount_ amount of tokens to be staked.
  /// @return bool true if successful.
  function stake(uint256 amount_) external returns (bool);

  /// @notice Unstake tokens.
  /// @param amount_ amount of tokens to be unstaked.
  /// @return bool true if successful.
  function unstake(uint256 amount_) external returns (bool);

  /// @notice Functionality for DAO to add benefits for all stakers.
  /// @param amount_ amount of wei to be shared among stakers.
  function addBenefits(uint256 amount_) external;

  /// @notice Sets DAO and Factory addresses.
  /// @param dao_ DAO address that this token governs.
  /// @param factory_ Factory address.
  function setDaoFactoryAddresses(address dao_, address factory_) external;

  /// @notice Functionality for owner to burn tokens.
  /// @param amount_ amount of tokens to burn.
  function burn(uint256 amount_) external;
}

