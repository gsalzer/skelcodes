// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ISupportingExternalReflection {
    function setReflectorAddress(address payable _reflectorAddress) external;
}

