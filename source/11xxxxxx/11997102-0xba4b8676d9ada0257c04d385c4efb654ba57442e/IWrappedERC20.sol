// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./IWrappedERC20Events.sol";

interface IWrappedERC20 is IERC20
{
    function wrappedToken() external view returns (IERC20);
    function depositTokens(uint256 _amount) external;
    function withdrawTokens(uint256 _amount) external;
    function burn(uint256 _amount) external;
}
