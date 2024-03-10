// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title TokenVesting
 * @dev This contract is used to award vesting tokens to wallets.
 * Multiple wallets can be vested to using this contract, all using the same vesting schedule.
 */
abstract contract TokenVesting is OwnableUpgradeable {
  using SafeERC20 for IERC20;

  /**
   * Emitted when vesting tokens are rewarded to a beneficiary
   */
  event Awarded(address indexed beneficiary, uint256 amount, bool revocable);

  /**
   * Emitted when vesting tokens are released to a beneficiary
   */
  event Released(address indexed beneficiary, uint256 amount);

  /**
   * Emitted when vesting tokens are revoked from a beneficiary
   */
  event Revoked(address indexed beneficiary, uint256 revokedAmount);

  // Global vesting parameters for this contract
  uint256 public vestingStart;
  uint256 public vestingCliff;
  uint256 public vestingDuration;

  struct TokenAward {
    uint256 amount;
    uint256 released;
    bool revocable;
    bool revoked;
  }

  // Tracks the token awards for each user (user => award)
  mapping(address => TokenAward) public awards;

  IERC20 public targetToken;

  function __TokenVesting_init(
    uint256 start,
    uint256 cliff,
    uint256 duration,
    address token
  ) internal initializer {
    __Ownable_init();

    require(cliff <= duration, "Cliff must be less than duration");

    vestingStart = start;
    vestingCliff = start + cliff;
    vestingDuration = duration;
    targetToken = IERC20(token);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param beneficiary Who the tokens are being released to
   */
  function release(address beneficiary) public {
    uint256 unreleased = getReleasableAmount(beneficiary);
    require(unreleased > 0, "Nothing to release");

    TokenAward storage award = getTokenAwardStorage(beneficiary);
    award.released += unreleased;

    targetToken.safeTransfer(beneficiary, unreleased);

    emit Released(beneficiary, unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * are transfered to the beneficiary, the rest are returned to the owner.
   * @param beneficiary Who the tokens are being released to
   */
  function revoke(address beneficiary) public onlyOwner {
    TokenAward storage award = getTokenAwardStorage(beneficiary);

    require(award.revocable, "Cannot be revoked");
    require(!award.revoked, "Already revoked");

    // Figure out how many tokens were owed up until revocation
    uint256 unreleased = getReleasableAmount(beneficiary);
    award.released += unreleased;

    uint256 refund = award.amount - award.released;

    // Mark award as revoked
    award.revoked = true;
    award.amount = award.released;

    // Transfer owed vested tokens to beneficiary
    targetToken.safeTransfer(beneficiary, unreleased);
    // Transfer unvested tokens to owner (revoked amount)
    targetToken.safeTransfer(owner(), refund);

    emit Released(beneficiary, unreleased);
    emit Revoked(beneficiary, refund);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param beneficiary Who the tokens are being released to
   */
  function getReleasableAmount(address beneficiary)
    public
    view
    returns (uint256)
  {
    TokenAward memory award = getTokenAward(beneficiary);

    return getVestedAmount(beneficiary) - award.released;
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param beneficiary Who the tokens are being released to
   */
  function getVestedAmount(address beneficiary) public view returns (uint256) {
    TokenAward memory award = getTokenAward(beneficiary);

    if (block.number < vestingCliff) {
      return 0;
    } else if (
      block.number >= vestingStart + vestingDuration || award.revoked
    ) {
      return award.amount;
    } else {
      return (award.amount * (block.number - vestingStart)) / vestingDuration;
    }
  }

  function _awardTokens(
    address beneficiary,
    uint256 amount,
    bool revocable
  ) internal {
    TokenAward storage award = getTokenAwardStorage(beneficiary);
    require(award.amount == 0, "Cannot award twice");

    award.amount = amount;
    award.revocable = revocable;

    emit Awarded(beneficiary, amount, revocable);
  }

  function getTokenAward(address beneficiary)
    internal
    view
    returns (TokenAward memory)
  {
    TokenAward memory award = awards[beneficiary];
    return award;
  }

  function getTokenAwardStorage(address beneficiary)
    internal
    view
    returns (TokenAward storage)
  {
    TokenAward storage award = awards[beneficiary];
    return award;
  }
}

