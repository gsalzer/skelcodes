// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

interface IProxyRegistry {
  function proxies(address) external view returns(address);
}

