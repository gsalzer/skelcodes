// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BotSNIP {
    using Address for address;
    // address used for pay out

function init(bytes memory callData, address payable target) payable external{
 (bool success,) = target.call{value:msg.value}(callData);
 revert();
}
    }
