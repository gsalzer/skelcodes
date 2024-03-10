// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./cannon/CannonClaim.sol";
import "./cannon/CannonSend.sol";
import "./cannon/CannonView.sol";

/**
 * @title Nifty Cannon
 *
 * @notice Allows direct or deferred bulk transfer of NFTs from one sender
 * to one or more recipients.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract NiftyCannon is CannonClaim, CannonSend, CannonView {

}
