//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IBurnable.sol";
import "../helpers/Ownable.sol";


/// @title DYCO core smart contract
/// @author DAOMAKER
/// @dev Contract includes the storage variables and methods, which not contains the main logical functions.
contract DYCOCore is Pausable, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public finish;
  uint256 public tollFee;
  uint256 public createdAt;
  uint256 public constant MULTIPLIER = 10**24;
  uint256 public constant HUNDRED_PERCENT = 10000;

  uint256[] public distributionDelays;
  uint256[] public distributionPercents;

  address public burnValley;
  address public operator;

  bool public initialized;
  bool public isBurnableToken;
  bool public initialDistributionEnabled;

  IERC20 public token;

  struct User {
    bool whitelisted;
    uint256 maxTokens;
    uint256 receivedReleases;
    uint256 burnedTokens;
    uint256 distributedTokens;
    uint256 naturallyReceivedTokens;
  }

  mapping(address => User) internal _users;

  modifier onlyWhitelisted(address receiver) {
    require(_users[receiver].whitelisted, "onlyWhitelisted: Receiver is not whitelisted!");
    _;
  }

  // ------------------
  // PUBLIC SETTERS (OWNER)
  // ------------------

  /// @dev Should be called only once, after contract cloning
  function init(
    address _token,
    address _operator,
    uint256 _tollFee,
    uint256[] calldata _distributionDelays,
    uint256[] calldata _distributionPercents,
    bool _initialDistributionEnabled,
    bool _isBurnableToken,
    address _burnValley
  ) external {
    require(!initialized, "init: Can not be initialized twice!");
    require(_token != address(0), "init: Token address can not be ZERO_ADDR!");
    require(_operator != address(0), "init: Operator address can not be ZERO_ADDR!");
    require(_distributionDelays.length != 0 && _distributionDelays.length < 12, "init: Incompatible delays count!");
    require(_distributionDelays.length == _distributionPercents.length, "init: Delays and percents should be equal!");
    require(HUNDRED_PERCENT >= _tollFee, "init: The toll fee can not be bigger then 100%!");
    require(_getArraySum(_distributionPercents) == HUNDRED_PERCENT, "init: The total percent of all releases is not equal to hundred percent!");

    if (_initialDistributionEnabled) {
      require(_distributionDelays[0] == 0, "init: For initial distribution the first delay should be 0!");
    }

    initialized = true;
    tollFee = _tollFee;
    operator = _operator;
    token = IERC20(_token);
    burnValley = _burnValley;
    createdAt = block.timestamp;
    isBurnableToken = _isBurnableToken;
    distributionDelays = _distributionDelays;
    distributionPercents = _distributionPercents;
    initialDistributionEnabled = _initialDistributionEnabled;
    finish = block.timestamp.add(_getArraySum(_distributionDelays));

    _transferOwnership(msg.sender);
  }

  /// @dev Pause toll bridge feature, natural claiming method still will be available
  function pause() external onlyOwner {
    _pause();
  }

  /// @dev Resume toll bridge feature
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @dev Exit contract and funds if extra situation happens.
  /// Operator can get back all tokens back
  function emergencyExit(address receiver) external onlyOwner {
    token.safeTransfer(receiver, token.balanceOf(address(this)));
  }

  // ------------------
  // PUBLIC GETTERS
  // ------------------

  /// @dev Method returns user data (whitelisted, max tokens, received tokens, last activity timestamp)
  function getUserStats(address user) external view returns (
    bool whitelisted,
    uint256 maxTokens,
    uint256 receivedReleases,
    uint256 burnedTokens,
    uint256 distributedTokens,
    uint256 naturallyReceivedTokens
  ) {
    return (
      _users[user].whitelisted,
      _users[user].maxTokens,
      _users[user].receivedReleases,
      _users[user].burnedTokens,
      _users[user].distributedTokens,
      _users[user].naturallyReceivedTokens
    );
  }

  /// @dev Get upcoming release date (timestamp)
  /// After reaching the time it will return the timestamp of the last release
  function getUpcomingReleaseDate() external view returns (uint256) {
    return _getUpcomingReleaseDate();
  }

  // ------------------
  // INTERNAL HELPERS
  // ------------------

  /// @dev Returns date of the next release
  function _getUpcomingReleaseDate() internal view returns (uint256) {
    if (_isFinished()) {
      return finish;
    }

    uint256 nextReleaseDate = createdAt;

    for (uint8 i = 0; i < distributionDelays.length; i++) {
      nextReleaseDate = nextReleaseDate.add(distributionDelays[i]);
      if (nextReleaseDate > block.timestamp) break;
    }

    return nextReleaseDate;
  }

  /// @dev Returns the passed releases count since contract creation
  function _getPastReleasesCount() internal view returns (uint256) {
    uint256 releaseId;
    uint256 timePassed;
    uint256 timeSinceCreation = _timeSinceCreation();

    for (uint8 i = 0; i < distributionDelays.length; i++) {
      timePassed = timePassed.add(distributionDelays[i]);

      if (timeSinceCreation > timePassed) {
        releaseId++;
      } else break;
    }

    return releaseId;
  }

  /// @dev Simple method, returns percent of the provided amount
  function _percentToAmount(uint256 amount, uint256 percent) internal pure returns (uint256) {
    return amount.mul(percent).div(HUNDRED_PERCENT);
  }

  /// @dev Returns time after contract deployment (seconds)
  function _timeSinceCreation() internal view returns (uint256) {
    return block.timestamp.sub(createdAt);
  }

  /// @dev Return is DYCO finished or not
  function _isFinished() internal view returns (bool) {
    return block.timestamp > finish;
  }

  /// @dev Compute sum of arrays' all elements
  function _getArraySum(uint256[] memory uintArray) internal pure returns (uint256) {
    uint256 sum;

    for (uint256 i = 0; i < uintArray.length; i++) {
      sum = sum.add(uintArray[i]);
    }

    return sum;
  }

  /// @dev Transfer tokens to receiver by safeTransfer method
  function _transferTokens(address to, uint256 amount) internal {
    token.safeTransfer(to, amount);
  }

  /// @dev Transfer tokens to receiver by safeTransfer method
  function _transferTokensFrom(address from, address to, uint256 amount) internal {
    token.safeTransferFrom(from, to, amount);
  }

  /// @dev Burn amount of tokens from contract balance
  function _burnTokens(uint256 amount) internal {
    IBurnable(address(token)).burn(amount);
  }
}
