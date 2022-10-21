// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "IERC20.sol";

/**
 * @title IIdeaToken
 * @author Alexander Schlindwein
 */
interface IIdeaToken is IERC20 {
    function initialize(string calldata __name, address owner) external;
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}
