// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
/// @title ERC223ReceivingContract - Extension for ERC20 Token 
/// @custom:version 1.0.0
abstract contract ERC223ReceivingContract {
/**
 * @dev Standard ERC223 function that will handle incoming token transfers.
 *
 * @param _from  Token sender address.
 * @param _value Amount of tokens.
 * @param _data  Transaction metadata.
 */

    function tokenFallback(address _from, uint256 _value, bytes memory _data) virtual public;
}

