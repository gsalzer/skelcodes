//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

interface IMintableBurnableERC20 is IERC20MetadataUpgradeable {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

