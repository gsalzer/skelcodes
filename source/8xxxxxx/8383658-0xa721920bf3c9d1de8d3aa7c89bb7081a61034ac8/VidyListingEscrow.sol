pragma solidity ^0.5.0;

import "./TokenTimelock.sol";
import "./SafeERC20.sol";

/**
 * Empty extension of openzeppelin's "TokenTimelock".  Allows us to
 * easily refer to this specific contract
 */
contract VidyListingEscrow is TokenTimelock {
  using SafeERC20 for IERC20;

  constructor(
    IERC20 token,
    address beneficiary,
    uint256 releaseTime
  ) TokenTimelock(token, beneficiary, releaseTime) public {

  }

}

