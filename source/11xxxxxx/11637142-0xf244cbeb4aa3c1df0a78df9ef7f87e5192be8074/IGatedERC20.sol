// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./IERC20.sol";
import "./ITransferGate.sol";

interface IGatedERC20 is IERC20
{
    function transferGate() external view returns (ITransferGate);

    function setTransferGate(ITransferGate _transferGate) external;
}
