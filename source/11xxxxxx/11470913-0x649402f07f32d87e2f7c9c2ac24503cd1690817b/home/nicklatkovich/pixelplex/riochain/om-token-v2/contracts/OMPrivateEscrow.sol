// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Escrow.sol";

contract OMPrivateEscrow is Escrow {
    constructor(IERC20 token_) public Escrow(token_) {}
}

