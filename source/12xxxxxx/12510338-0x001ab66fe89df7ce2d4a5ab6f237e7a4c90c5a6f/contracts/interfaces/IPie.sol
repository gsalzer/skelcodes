//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPie is IERC20 {
    function joinPool(uint256 _amount, uint16 _referral) external;
    function exitPool(uint256 _amount) external;
    function calcTokensForAmount(uint256 _amount) external view  returns(address[] memory tokens, uint256[] memory amounts);
}
