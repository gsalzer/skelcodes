// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

import {INameIdentifier} from "contracts/common/Imports.sol";

abstract contract ConvexAaveConstants is INameIdentifier {
    string public constant override NAME = "convex-aave";

    uint256 public constant PID = 24;

    address public constant STABLE_SWAP_ADDRESS =
        0xDeBF20617708857ebe4F679508E7b7863a8A8EeE;
    address public constant LP_TOKEN_ADDRESS =
        0xFd2a8fA60Abd58Efe3EeE34dd494cD491dC14900;
    address public constant REWARD_CONTRACT_ADDRESS =
        0xE82c1eB4BC6F92f85BF7EB6421ab3b882C3F5a7B;
}

