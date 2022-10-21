// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ShifterPoolLib } from "../ShifterPoolLib.sol";

contract ShifterPoolQuery is Ownable {
  ShifterPoolLib.Isolate isolate;
}

