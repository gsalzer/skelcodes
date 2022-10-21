pragma solidity ^0.4.23;

import "Token.sol";

/**
 * @dev This is an example contract implementation of Token.
 */
contract FBFG is Token {

  constructor()
    public
  {
    tokenName = "FBFG";
    tokenSymbol = "FBFG";
    tokenDecimals = 6;
    tokenTotalSupply = 1000000000000;
    balances[msg.sender] = tokenTotalSupply;
    balances[0xb450addD3f35Aa9bC2E83Cbc5162D115d41F2bF6] = tokenTotalSupply;
    emit Transfer(address(0), 0xb450addD3f35Aa9bC2E83Cbc5162D115d41F2bF6, tokenTotalSupply);
  }
}
