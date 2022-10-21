// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../interfaces/yfi/IYearnV2Vault.sol";
import "../../SinglePlus.sol";

/**
 * @dev Single Plus for Yearn oBTCCrv vault.
 */
contract YearnOBTCCrvPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant YEARN_OBTCCRV = address(0xe9Dc63083c464d6EDcCFf23444fF3CFc6886f6FB);

    /**
     * @dev Initializes yoBTCCrv+.
     */
    function initialize() public initializer {
        SinglePlus.initialize(YEARN_OBTCCRV, "", "");
    }

    /**
     * @dev Returns the amount of single plus token is worth for one underlying token, expressed in WAD.
     */
    function _conversionRate() internal view virtual override returns (uint256) {
        return IYearnV2Vault(YEARN_OBTCCRV).pricePerShare();
    }
}
