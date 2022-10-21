// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import {
  MintableBurnableSyntheticToken
} from './MintableBurnableSyntheticToken.sol';
import {MintableBurnableIERC20} from './interfaces/MintableBurnableIERC20.sol';
import {
  Lockable
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/Lockable.sol';

/**
 * @title Factory for creating new mintable and burnable tokens.
 */
contract MintableBurnableTokenFactory is Lockable {
  /**
   * @notice Create a new token and return it to the caller.
   * @dev The caller will become the only minter and burner and the new admin capable of assigning the roles.
   * @param tokenName used to describe the new token.
   * @param tokenSymbol short ticker abbreviation of the name. Ideally < 5 chars.
   * @param tokenDecimals used to define the precision used in the token's numerical representation.
   * @return newToken an instance of the newly created token interface.
   */
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) public virtual nonReentrant() returns (MintableBurnableIERC20 newToken) {
    MintableBurnableSyntheticToken mintableToken =
      new MintableBurnableSyntheticToken(tokenName, tokenSymbol, tokenDecimals);
    mintableToken.addAdmin(msg.sender);
    mintableToken.renounceAdmin();
    newToken = MintableBurnableIERC20(address(mintableToken));
  }
}

