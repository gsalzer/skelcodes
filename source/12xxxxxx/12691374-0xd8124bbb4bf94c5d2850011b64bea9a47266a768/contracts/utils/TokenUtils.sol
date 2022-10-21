// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IERC20Optional.sol";

library TokenUtils {
    function decimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("decimals()"));
        require(success, "TokenUtils: no decimals");
        uint8 _decimals = abi.decode(data, (uint8));
        return _decimals;
    }
}

