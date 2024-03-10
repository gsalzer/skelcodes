//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface IDYCO {
  function pause() external;
  function unpause() external;
  function emergencyExit(address receiver) external;
  function claimTokens(address receiver, uint256 amount) external returns (uint256, uint256);
  function init(
    address token,
    address operator,
    uint256 tollFee,
    uint256[] calldata distributionDelays,
    uint256[] calldata distributionPercents,
    bool initialDistributionEnabled,
    bool isBurnableToken,
    address burnValley
  ) external;
  function addWhitelistedUsers(
    address[] calldata users,
    uint256[] calldata amounts
  ) external;
}
