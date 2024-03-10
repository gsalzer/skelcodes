// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "../StrategyBase.sol";
import "../../interfaces/IController.sol";
import "../../interfaces/curve/ICurveGauge.sol";

/**
 * @dev Base strategy for Curve's LP token, e.g. renCrv, hbtcCrv, tbtcCrv.
 */
abstract contract StrategyCurveLpBase is StrategyBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    event Harvested(address indexed token, uint256 amount, uint256 feeAmount);

    // Constants
    address public constant crv = address(0xD533a949740bb3306d119CC777fa900bA034cd52);  // CRV token
    address public constant mintr = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // Token minter
    address public constant uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // UniswapV2Router02
    address public constant weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH token. Used for crv -> weth -> wbtc route
    address public constant wbtc = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // WBTC token. Used for crv -> weth -> wbtc route

    // Pool parameters
    address public guage;
    address public curve;

    constructor(address _vault, address _guage, address _curve) StrategyBase(_vault) internal {
        require(_guage != address(0x0), "guage not set");
        require(_curve != address(0x0), "curve not set");
        guage = _guage;
        curve = _curve;
    }

    /**
     * @dev Deposits all renCRV into Curve liquidity gauge to earn CRV.
     */
    function deposit() public override {
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _want = want.balanceOf(address(this));
        if (_want > 0) {
            want.safeApprove(guage, 0);
            want.safeApprove(guage, _want);
            ICurveGauge(guage).deposit(_want);
        }
    }

    /**
     * @dev Withdraw partial funds, normally used with a vault withdrawal
     */
    function withdraw(uint256 _amount) public override {
        require(msg.sender == vault, "not vault");
        IERC20Upgradeable want = IERC20Upgradeable(token());
        uint256 _balance = want.balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }
        if (withdrawalFee > 0) {
            uint256 _feeAmount = _amount.mul(withdrawalFee).div(FEE_MAX);
            want.safeTransfer(IController(controller()).treasury(), _feeAmount);
            _amount = _amount.sub(_feeAmount);
        }

        want.safeTransfer(vault, _amount);
    }

    /**
     * @dev Withdraw all funds, normally used when migrating strategies
     * No withdrawal fee is charged when withdrawing all assets.
     */
    function withdrawAll() public override returns (uint256 balance) {
        require(msg.sender == vault, "not vault");
        ICurveGauge(guage).withdraw(ICurveGauge(guage).balanceOf(address(this)));

        IERC20Upgradeable want = IERC20Upgradeable(token());
        balance = want.balanceOf(address(this));
        want.safeTransfer(vault, balance);
    }

    /**
     * @dev Withdraw some tokens from the gauge.
     */
    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        ICurveGauge(guage).withdraw(_amount);
        return _amount;
    }

    /**
     * @dev Returns the amount of tokens deposited in the strategy.
     */
    function balanceOfWant() public view returns (uint256) {
        return IERC20Upgradeable(token()).balanceOf(address(this));
    }

    /**
     * @dev Returns the amount of tokens deposited in the gauge.
     */
    function balanceOfPool() public view returns (uint256) {
        return ICurveGauge(guage).balanceOf(address(this));
    }

    /**
     * @dev Returns the amount of tokens deposited in strategy + gauge.
     */
    function balanceOf() public view override returns (uint256) {
        return balanceOfWant().add(balanceOfPool());
    }

    function _getProtectedTokens() internal virtual override view returns (address[] memory) {
        address[] memory protectedTokens = new address[](3);
        protectedTokens[0] = token();
        protectedTokens[1] = wbtc;
        protectedTokens[2] = crv;
        return protectedTokens;
    }
}
