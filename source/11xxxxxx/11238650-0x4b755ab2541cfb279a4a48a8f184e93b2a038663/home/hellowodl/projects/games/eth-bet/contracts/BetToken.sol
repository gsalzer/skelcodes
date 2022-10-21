pragma solidity ^0.6.9;

import "./BetToken/BetTokenHolder.sol";
import "./BetToken/BetTokenRecipient.sol";
import "./BetToken/BetTokenSender.sol";

abstract contract BetToken is BetTokenHolder, BetTokenSender, BetTokenRecipient {
    constructor (
        address tokenAddress
    ) public BetTokenHolder(tokenAddress) {}
}
