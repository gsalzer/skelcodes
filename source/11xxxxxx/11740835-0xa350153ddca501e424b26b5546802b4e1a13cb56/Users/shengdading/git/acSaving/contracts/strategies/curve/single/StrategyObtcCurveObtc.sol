// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../StrategyCurveBase.sol";
import "../../../interfaces/IVault.sol";
import "../../../interfaces/curve/ICurveFi.sol";

/**
 * @dev Strategy for OBTC on Curve's OBTC pool.
 * Important tokens:
 * - want: OBTC
 * - lp: obtcCrv
 * - lpVault: obtcCrvv
 */
contract StrategyObtcCurveObtc is StrategyCurveBase {
    
    // Pool parameters
    address public constant OBTCCRV_VAULT = address(0xa73b91094304cd7bd1e67a839f63e287B29c0f65); // obtcCrv vault
    address public constant OBTC_SWAP = address(0xd81dA8D904b52208541Bade1bD6595D8a251F8dd); // OBTC swap

    /**
     * @dev Initializes the strategy.
     */
    function initialize(address _vault) public initializer {
        __StrategyCurveBase__init(_vault, OBTCCRV_VAULT, OBTC_SWAP);
    }

    /**
     * @dev Deposits the want token into Curve in exchange for lp token.
     * @param _want Amount of want token to deposit.
     * @param _minAmount Minimum LP token to receive.
     */
    function _depositToCurve(uint256 _want, uint256 _minAmount) internal override {
        ICurveFi(curve).add_liquidity([_want, 0], _minAmount);
    }

    /**
     * @dev Withdraws the want token from Curve by burning lp token.
     * @param _lp Amount of LP token to burn.
     * @param _minAmount Minimum want token to receive.
     */
    function _withdrawFromCurve(uint256 _lp, uint256 _minAmount) internal override {
        ICurveFi(curve).remove_liquidity_one_coin(_lp, 0, _minAmount);
    }
}
