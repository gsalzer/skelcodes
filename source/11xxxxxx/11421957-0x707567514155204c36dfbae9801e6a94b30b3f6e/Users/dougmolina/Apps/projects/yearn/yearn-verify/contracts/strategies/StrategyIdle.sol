// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use

// Feel free to change this version of Solidity. We support >=0.6.0 <0.7.0;
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// These are the core Yearn libraries
import {BaseStrategy, StrategyParams} from "../BaseStrategyNew.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "../../interfaces/Idle/IIdleTokenV3_1.sol";
import "../../interfaces/Idle/IdleReservoir.sol";
import "../../interfaces/Uniswap/IUniswapRouter.sol";

contract StrategyIdle is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public immutable uniswapRouterV2;
    address public immutable comp;
    address public immutable idle;
    address public immutable weth;
    address public immutable idleReservoir;
    address public immutable idleYieldToken;
    address public immutable referral;

    address[] public uniswapCompPath;
    address[] public uniswapIdlePath;

    bool public checkVirtualPrice;
    uint256 public lastVirtualPrice;

    modifier updateVirtualPrice() {
        if (checkVirtualPrice) {
            require(
                lastVirtualPrice <= IIdleTokenV3_1(idleYieldToken).tokenPrice(),
                "Virtual price is increasing from the last time, potential losses"
            );
        }
        _;
        lastVirtualPrice = IIdleTokenV3_1(idleYieldToken).tokenPrice();
    }

    constructor(
        address _vault,
        address _comp,
        address _idle,
        address _weth,
        address _idleReservoir,
        address _idleYieldToken,
        address _referral,
        address _uniswapRouterV2
    ) public BaseStrategy(_vault) {
        comp = _comp;
        idle = _idle;
        weth = _weth;
        idleReservoir = _idleReservoir;
        idleYieldToken = _idleYieldToken;
        referral = _referral;

        uniswapRouterV2 = _uniswapRouterV2;
        uniswapCompPath = [_comp, _weth, address(want)];
        uniswapIdlePath = [_idle, _weth, address(want)];

        checkVirtualPrice = true;
        lastVirtualPrice = IIdleTokenV3_1(_idleYieldToken).tokenPrice();
    }

    function setCheckVirtualPrice(bool _checkVirtualPrice) public onlyGovernance {
        checkVirtualPrice = _checkVirtualPrice;
    }

    // ******** OVERRIDE THESE METHODS FROM BASE CONTRACT ************

    function name() external virtual override pure returns (string memory) {
        return "StrategyIdle";
    }

    function estimatedTotalAssets() public override view returns (uint256) {
        // TODO: Build a more accurate estimate using the value of all positions in terms of `want`
        return want.balanceOf(address(this)).add(balanceOnIdle()); //TODO: estimate COMP+IDLE value
    }

    /*
     * Perform any strategy unwinding or other calls necessary to capture the "free return"
     * this strategy has generated since the last time it's core position(s) were adjusted.
     * Examples include unwrapping extra rewards. This call is only used during "normal operation"
     * of a Strategy, and should be optimized to minimize losses as much as possible. This method
     * returns any realized profits and/or realized losses incurred, and should return the total
     * amounts of profits/losses/debt payments (in `want` tokens) for the Vault's accounting
     * (e.g. `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`. It is okay for it
     *       to be less than `_debtOutstanding`, as that should only used as a guide for how much
     *       is left to pay back. Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        // Assure IdleController has IDLE tokens
        IdleReservoir(idleReservoir).drip();

        // Try to pay debt asap
        if (_debtOutstanding > 0) {
            uint256 _amountFreed = liquidatePosition(_debtOutstanding);
            // Using Math.min() since we might free more than needed
            _debtPayment = Math.min(_amountFreed, _debtOutstanding);
        }

        // Claim always is cheaper. In the worst case we already claimed in the prev step
        // and the gas cost will be higher
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(0);

        // If we have IDLE or COMP, let's convert them!
        // This is done in a separate step since there might have been
        // a migration or an exitPosition

        // 1. COMP => IDLE via ETH
        // 2. total IDLE => underlying via ETH
        // This might be > 0 because of a strategy migration
        uint256 balanceOfWantBeforeSwap = balanceOfWant();
        _liquidateComp();
        _liquidateIdle();
        _profit = balanceOfWant().sub(balanceOfWantBeforeSwap);
    }

    /*
     * Perform any adjustments to the core position(s) of this strategy given
     * what change the Vault made in the "investable capital" available to the
     * strategy. Note that all "free capital" in the strategy after the report
     * was made is available for reinvestment. Also note that this number could
     * be 0, and you should handle that scenario accordingly.
     */
    function adjustPosition(uint256 _debtOutstanding) internal override updateVirtualPrice {
        // TODO: Do something to invest excess `want` tokens (from the Vault) into your positions
        // NOTE: Try to adjust positions so that `_debtOutstanding` can be freed up on *next* harvest (not immediately)

        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        uint256 _wantAvailable = balanceOfWant().sub(_debtOutstanding);
        if (_wantAvailable > 0) {
            want.safeApprove(idleYieldToken, 0);
            want.safeApprove(idleYieldToken, _wantAvailable);
            IIdleTokenV3_1(idleYieldToken).mintIdleToken(_wantAvailable, true, referral);
        }
    }

    /*
     * Make as much capital as possible "free" for the Vault to take. Some
     * slippage is allowed. The goal is for the strategy to divest as quickly as possible
     * while not suffering exorbitant losses. This function is used during emergency exit
     * instead of `prepareReturn()`. This method returns any realized losses incurred, and
     * should also return the amount of `want` tokens available to repay outstanding debt
     * to the Vault.
     */
    function exitPosition(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        if (checkVirtualPrice) {
            // Temporarily suspend virtual price check
            checkVirtualPrice = false;
            (_profit, _loss, _debtPayment) = prepareReturn(_debtOutstanding);
            checkVirtualPrice = true;
        } else {
            return prepareReturn(_debtOutstanding);
        }
    }

    /*
     * Liquidate as many assets as possible to `want`, irregardless of slippage,
     * up to `_amountNeeded`. Any excess should be re-invested here as well.
     */
    function liquidatePosition(uint256 _amountNeeded) internal override updateVirtualPrice returns (uint256 _amountFreed) {
        // TODO: Do stuff here to free up to `_amountNeeded` from all positions back into `want`
        // NOTE: Return `_amountFreed`, which should be `<= _amountNeeded`

        if (balanceOfWant() < _amountNeeded) {
            uint256 currentVirtualPrice = IIdleTokenV3_1(idleYieldToken).tokenPrice();

            // Note: potential drift by 1 wei, reduce to max balance in the case approx is rounded up
            uint256 valueToRedeemApprox = (_amountNeeded.sub(balanceOfWant())).mul(1e18).div(currentVirtualPrice) + 1;
            uint256 valueToRedeem = Math.min(valueToRedeemApprox, IERC20(idleYieldToken).balanceOf(address(this)));

            IIdleTokenV3_1(idleYieldToken).redeemIdleToken(valueToRedeem);
        }

        _amountFreed = balanceOfWant();
    }

    // NOTE: Can override `tendTrigger` and `harvestTrigger` if necessary

    function harvestTrigger(uint256 callCost) public override view returns (bool) {
        return super.harvestTrigger(ethToWant(callCost));
    }

    function prepareMigration(address _newStrategy) internal override {
        // TODO: Transfer any non-`want` tokens to the new strategy
        // NOTE: `migrate` will automatically forward all `want` in this strategy to the new one

        uint256 balance = IERC20(idleYieldToken).balanceOf(address(this));

        // this automatically claims the COMP and IDLE gov tokens
        IIdleTokenV3_1(idleYieldToken).redeemIdleToken(balance);

        // Transfer COMP and IDLE to new strategy
        IERC20(comp).transfer(_newStrategy, IERC20(comp).balanceOf(address(this)));
        IERC20(idle).transfer(_newStrategy, IERC20(idle).balanceOf(address(this)));
    }

    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](3);

        protected[0] = idleYieldToken;
        protected[1] = idle;
        protected[2] = comp;

        return protected;
    }

    function balanceOnIdle() public view returns (uint256) {
        uint256 currentVirtualPrice = IIdleTokenV3_1(idleYieldToken).tokenPrice();
        return IERC20(idleYieldToken).balanceOf(address(this)).mul(currentVirtualPrice).div(1e18);
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function ethToWant(uint256 _amount) public view returns (uint256) {
        if (_amount == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(want);
        uint256[] memory amounts = IUniswapRouter(uniswapRouterV2).getAmountsOut(_amount, path);

        return amounts[amounts.length - 1];
    }

    function _liquidateComp() internal {
        uint256 compBalance = IERC20(comp).balanceOf(address(this));
        if (compBalance > 0) {
            IERC20(comp).safeApprove(uniswapRouterV2, 0);
            IERC20(comp).safeApprove(uniswapRouterV2, compBalance);
            IUniswapRouter(uniswapRouterV2).swapExactTokensForTokens(compBalance, 1, uniswapCompPath, address(this), block.timestamp);
        }
    }

    function _liquidateIdle() internal {
        uint256 idleBalance = IERC20(idle).balanceOf(address(this));
        if (idleBalance > 0) {
            IERC20(idle).safeApprove(uniswapRouterV2, 0);
            IERC20(idle).safeApprove(uniswapRouterV2, idleBalance);

            IUniswapRouter(uniswapRouterV2).swapExactTokensForTokens(idleBalance, 1, uniswapIdlePath, address(this), block.timestamp);
        }
    }
}

