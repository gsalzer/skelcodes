// SPDX-License-Identifier: MIT

pragma solidity >=0.4.25 <0.7.0;
/** OpenZeppelin Dependencies Upgradeable */
// import "@openzeppelin/contracts-upgradeable/contracts/proxy/Initializable.sol";
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
/** OpenZepplin non-upgradeable Swap Token (hex3t) */
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
/** Local Interfaces */
import '../NativeSwap.sol';

contract NativeSwapRestorable is NativeSwap {
    /* Setter methods for contract migration */
    function setStart(uint256 _start) external onlyMigrator {
        start = _start;
    }
}

