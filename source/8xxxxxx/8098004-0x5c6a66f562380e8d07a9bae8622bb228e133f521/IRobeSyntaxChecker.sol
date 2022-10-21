pragma solidity ^0.5.0;

/**
  * @title Syntax Checker for Robe-based NFT contract
  * 
  * @author Marco Vasapollo <ceo@metaring.com>
  * @author Alessandro Mario Lagana Toschi <alet@risepic.com>
*/
interface IRobeSyntaxChecker {

    /**
     * @return true if the given payload respects the syntax of the Robe NFT reachable at the given robeAddress, false otherwhise
     */
    function check(uint256 rootTokenId, uint256 newTokenId, address owner, bytes calldata payload, address robeAddress) external view returns(bool);
}
