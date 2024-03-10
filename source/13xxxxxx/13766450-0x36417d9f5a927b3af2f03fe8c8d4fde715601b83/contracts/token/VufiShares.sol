// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import {ERC20PresetFixedSupply} from "../external/openzeppelin/contracts/presets/ERC20PresetFixedSupply.sol";
import {ERC20Permit} from "../external/openzeppelin/contracts/drafts/ERC20Permit.sol";

contract VufiShares is ERC20PresetFixedSupply, ERC20Permit {
  // solhint-disable-next-line no-empty-blocks
  constructor() ERC20PresetFixedSupply("Vufi Shares", "VUFIS", 1000000000 ether, msg.sender) ERC20Permit("Vufi Shares") {}
}

