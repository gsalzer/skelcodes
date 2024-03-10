pragma solidity ^0.6.12;
import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract AnimalMoneyToken is ERC20PresetMinterPauser {
  constructor() public ERC20PresetMinterPauser("Animal Money", "ANIMAL") {}
}

