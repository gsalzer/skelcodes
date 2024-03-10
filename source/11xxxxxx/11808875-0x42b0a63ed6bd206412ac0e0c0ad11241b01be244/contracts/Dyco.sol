//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "./helpers/DYCOCore.sol";


/// @title DYCO smart contract
/// @author DAOMAKER
/// @notice Contract calculates, distribute and keep the investors state and balances
/// @dev The contract accepts calls only from DYCO factory contract (owner)
/// All percental variables uses x100, eg: 15% should be provided as 1500
contract DYCO is DYCOCore {
  using SafeMath for uint256;

  // ------------------
  // OWNER PUBLIC METHODS
  // ------------------

  /// @dev Operator should add whitelisted users with this method
  /// It can be called several times for big amount of users
  function addWhitelistedUsers(
    address[] memory _usersArray,
    uint256[] memory _amountsArray
  ) external onlyOwner {
    require(initialized, "addWhitelistedUsers: Initialization should be done before calling this method!");
    require(_usersArray.length != 0, "addWhitelistedUsers: could not be 0 length array!");
    require(_usersArray.length == _amountsArray.length, "addWhitelistedUsers: could not be different length arrays!");

    uint256 totalTokensForUsers;

    for (uint256 i = 0; i < _usersArray.length; i++) {
      address user = _usersArray[i];
      uint256 amount = _amountsArray[i];

      require(!_users[user].whitelisted, "addWhitelistedUsers: user duplication!");

      _users[user] = User({
        whitelisted: true,
        maxTokens: amount,
        receivedReleases: 0,
        burnedTokens: 0,
        distributedTokens: 0,
        naturallyReceivedTokens: 0
      });

      if (initialDistributionEnabled) {
        uint256 tokensPerRelease = _getTokensPerRelease(user, 0, amount);
        _users[user].receivedReleases = 1;
        _users[user].distributedTokens = tokensPerRelease;
        _users[user].naturallyReceivedTokens = tokensPerRelease;

        _transferTokensFrom(operator, user, tokensPerRelease);
        totalTokensForUsers = totalTokensForUsers.add(amount.sub(tokensPerRelease));
      } else {
        totalTokensForUsers = totalTokensForUsers.add(amount);
      }
    }

    _transferTokensFrom(operator, address(this), totalTokensForUsers);
  }

  // ------------------
  // PUBLIC SETTERS
  // ------------------

  /// @dev Method automatically calculates and knows which feature to use (natural nor bridge)
  /// It will never been reverted (only if toll bridge paused).
  function claimTokens(address receiver, uint256 amount) external onlyOwner onlyWhitelisted(receiver) returns (
    uint256 burnableTokens,
    uint256 transferableTokens
  ) {
    require(amount != 0, "claimTokens: Amount should be bigger 0!");
    require(receiver != address(0), "claimTokens: Receiver can not be zero address!");

    if (amount > _users[receiver].maxTokens.sub(_users[receiver].distributedTokens)) {
      amount = _users[receiver].maxTokens.sub(_users[receiver].distributedTokens);
    }

    uint256 naturalAvailableTokens = _getNaturalAvailableTokens(receiver);

    if (amount > naturalAvailableTokens && !_isFinished()) {
      require(!paused(), "claimTokens: Claiming tokens via toll bridge is paused!");

      if (naturalAvailableTokens != 0) {
        _users[receiver].receivedReleases = _getPastReleasesCount();
        _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(naturalAvailableTokens);
        _users[receiver].naturallyReceivedTokens = _users[receiver].naturallyReceivedTokens.add(naturalAvailableTokens);

        transferableTokens = naturalAvailableTokens;
      }

      uint256 overageAmount = amount.sub(naturalAvailableTokens);
      (uint256 burnPercent, uint256 transferPercent) = _getBurnAndTransferPercents(receiver);
      burnableTokens = _percentToAmount(overageAmount, burnPercent);
      uint256 tollBridgeTransferableTokens = _percentToAmount(overageAmount, transferPercent);

      transferableTokens = transferableTokens.add(tollBridgeTransferableTokens);
      _users[receiver].burnedTokens = _users[receiver].burnedTokens.add(burnableTokens);
      _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(tollBridgeTransferableTokens.add(burnableTokens));
    } else {
      if (amount != naturalAvailableTokens) {
        amount = naturalAvailableTokens;
      }

      _users[receiver].receivedReleases = _getPastReleasesCount();
      _users[receiver].distributedTokens = _users[receiver].distributedTokens.add(amount);
      _users[receiver].naturallyReceivedTokens = _users[receiver].naturallyReceivedTokens.add(amount);

      transferableTokens = amount;
    }

    _transferTokens(receiver, transferableTokens);
    if (burnableTokens != 0) {
      if (isBurnableToken) {
        _burnTokens(burnableTokens);
      } else {
        _transferTokens(burnValley, burnableTokens);
      }
    }

    return (
      burnableTokens,
      transferableTokens
    );
  }

  // ------------------
  // PUBLIC GETTERS
  // ------------------

  /// @dev Method returns ONLY natural available tokens, without toll bridge tokens
  function getNaturalAvailable(address user) external view returns (uint256) {
    return _getNaturalAvailableTokens(user);
  }

  // ------------------
  // INTERNAL METHODS
  // ------------------

  /// @dev Method calculates percent of toll bridge (transferable/burnable
  /// The formula is following:
  /// ----------------
  /// TOKENS_TO_CLAIM = 100 - [ (100 - X) * (Y * (A - Z) / A) + B * (Z / A) ]
  /// TOKENS_TO_BURN = 100 - TOKENS_TO_CLAIM
  /// ----------------
  /// X => at the time of claim, percentage of tokens naturally distributed
  /// Y => the percent of tokens burned for claims right after TGE (cost to instant flippers)
  /// A => amount of days for full distribution
  /// Z => days since TGE
  /// B => half of final distribution
  /// ----------------
  /// It uses the current state of the user (naturallyReceivedTokens), and returns 2 percent values
  /// Percents can be used only for this state, and will be changed after call
  function _getBurnAndTransferPercents(address user) private view returns (uint256, uint256) {
    uint256 burnPercent;
    uint256 transferPercent;
    uint256 timeSinceCreation = _timeSinceCreation();
    uint256 naturallyClaimedPercent = (_users[user].naturallyReceivedTokens.mul(HUNDRED_PERCENT)).div(_users[user].maxTokens);
    uint256 fullDistributionDelay = finish.sub(createdAt);

    burnPercent = (HUNDRED_PERCENT.sub(naturallyClaimedPercent))
      .mul((MULTIPLIER.mul(tollFee).mul(fullDistributionDelay.sub(timeSinceCreation))).div(fullDistributionDelay.mul(HUNDRED_PERCENT)))
      .add(MULTIPLIER.mul((distributionPercents[distributionPercents.length - 1].div(2)).mul(timeSinceCreation)).div(fullDistributionDelay))
      .div(MULTIPLIER);
    transferPercent = HUNDRED_PERCENT.sub(burnPercent);

    return (
      burnPercent,
      transferPercent
    );
  }

  function _getNaturalAvailableTokens(address user) internal view returns (uint256) {
    uint256 naturalAvailableTokens;
    uint256 receivedReleases = _users[user].receivedReleases;
    uint256 missedReleases = _getPastReleasesCount().sub(receivedReleases);
    uint256 availableTokens = _users[user].maxTokens.sub(_users[user].distributedTokens);

    while (missedReleases > 0) {
      uint256 tokensPerRelease = _getTokensPerRelease(user, receivedReleases, availableTokens);
      availableTokens = availableTokens.sub(tokensPerRelease);
      naturalAvailableTokens = naturalAvailableTokens.add(tokensPerRelease);

      missedReleases--;
      receivedReleases++;
    }

    return naturalAvailableTokens;
  }

  /// @dev Returns tokens of provided release of the certain user
  /// The formula is following:
  /// ----------------
  /// RELEASE_PERCENT * LEFT_TOKENS / (RELEASE_PERCENT + REST_PERCENTS_SUM)
  function _getTokensPerRelease(address user, uint256 releaseId, uint256 leftTokens) internal view returns (uint256) {
    (uint256 releasePercent, uint256 restPercents) = _getReleaseAndRestPercents(releaseId);

    return (releasePercent.mul(leftTokens).div(releasePercent.add(restPercents)));
  }

  /// @dev Returns the percent of thee current release and sum of the rest releases
  function _getReleaseAndRestPercents(uint256 releaseId) internal view returns (uint256, uint256) {
    uint256 restPercents = HUNDRED_PERCENT;
    uint256 releasePercent = distributionPercents[releaseId];

    for (uint8 i = 0; i <= releaseId; i++) {
      restPercents = restPercents.sub(distributionPercents[i]);
    }

    return (releasePercent, restPercents);
  }
}
