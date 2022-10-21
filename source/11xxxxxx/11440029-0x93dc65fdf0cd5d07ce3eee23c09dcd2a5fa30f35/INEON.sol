// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface INEON {
    function transferWithoutFee(address recipient, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}
