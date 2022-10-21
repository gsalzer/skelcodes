pragma solidity ^0.4.26;

import "./ERC20Token.sol";

contract SNS is ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 private constant DECIMALS = 18;
    uint256 private constant TOTAL_SUPPLY = 499 * 10 ** 8 * 10**DECIMALS;

    /**
     * @param _issuer The address of the owner.
     */
    constructor(address _issuer) public Owned(_issuer){
        name = "Skyrim Network";
        symbol = "SNS";
        decimals = uint8(DECIMALS);
        totalSupply = TOTAL_SUPPLY;
        balances[_issuer] = TOTAL_SUPPLY;
        emit Transfer(address(0), _issuer, TOTAL_SUPPLY);
    }
}

