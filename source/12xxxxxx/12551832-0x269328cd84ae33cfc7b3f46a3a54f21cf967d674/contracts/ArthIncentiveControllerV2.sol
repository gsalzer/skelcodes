// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IIncentiveController} from "./IIncentiveController.sol";

contract ArthIncentiveControllerV2 is Ownable, IIncentiveController {
    address public pair;
    mapping(address => bool) public whitelist;

    constructor(address pair_, address owner) {
        pair = pair_;
        transferOwnership(owner);
    }

    modifier onlyPair {
        require(msg.sender == pair, "Controller: Forbidden");
        _;
    }

    function addToWhitelist(address target) external onlyOwner {
        whitelist[target] = true;
    }

    function removeFromWhitelist(address target) external onlyOwner {
        whitelist[target] = false;
    }

    /**
     * This is the function that burns the MAHA and returns how much ARTH should
     * actually be spent.
     *
     * Note we are always selling tokenA.
     */
    function conductChecks(
        uint112 reserveA,
        uint112 reserveB,
        uint256 priceALast,
        uint256 priceBLast,
        uint256 amountOutA,
        uint256 amountOutB,
        uint256 amountInA,
        uint256 amountInB,
        address from,
        address to
    ) external override onlyPair {
        // The to nd from address has to be whitelisted.
        require(whitelist[to], "ArthIncentiveControllerV2: FORBIDDEN");
        require(whitelist[from], "ArthIncentiveControllerV2: FORBIDDEN");
    }
}

