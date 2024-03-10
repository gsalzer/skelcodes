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
import '../Token.sol';

contract TokenRestorable is Token {
    /* Setter methods for contract migration */
    function setNormalVariables(uint256 _swapTokenBalance)
        external
        onlyMigrator
    {
        swapTokenBalance = _swapTokenBalance;
    }

    function bulkMint(
        address[] calldata userAddresses,
        uint256[] calldata amounts
    ) external onlyMigrator {
        for (uint256 idx = 0; idx < userAddresses.length; idx = idx + 1) {
            _mint(userAddresses[idx], amounts[idx]);
        }
    }
}

