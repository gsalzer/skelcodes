// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/utils/Address.sol";
import "./CurveFarm.sol";
import "../../utils/Console.sol";

contract Curve3PoolFarm is CurveFarm {
  using Address for address;

  constructor (address pool, address[] memory rewards) public CurveFarm(pool, rewards) {
  }

}
