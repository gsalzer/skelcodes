// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../../SinglePlus.sol";
import "../../interfaces/curve/ICurveFi.sol";
import "../../interfaces/curve/ICurveMinter.sol";
import "../../interfaces/curve/ICurveGauge.sol";
import "../../interfaces/uniswap/IUniswapRouter.sol";

/**
 * @dev Single plus for sbtcCrv.
 */
contract SbtcCrvPlus is SinglePlus {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);  // CRV token
    address public constant MINTER = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0); // Token minter
    address public constant UNISWAP = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);  // Uniswap RouterV2
    address public constant SUSHISWAP = address(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);    // Sushiswap RouterV2
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // WETH token. Used for crv -> weth -> wbtc route
    address public constant WBTC = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // WBTC token. Used for crv -> weth -> wbtc route

    address public constant SBTCCRV = address(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3);
    address public constant SBTCCRV_GAUGE = address(0x705350c4BcD35c9441419DdD5d2f097d7a55410F); // sbtcCrv gauge
    address public constant SBTC_SWAP = address(0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714); // SBTC swap

    /**
     * @dev Initializes sBTCCrv+.
     */
    function initialize() public initializer {
        SinglePlus.initialize(SBTCCRV, "", "");
    }

    /**
     * @dev Retrive the underlying assets from the investment.
     * Only governance or strategist can call this function.
     */
    function divest() public virtual override onlyStrategist {
        ICurveGauge _gauge = ICurveGauge(SBTCCRV_GAUGE);
        _gauge.withdraw(_gauge.balanceOf(address(this)));
    }

    /**
     * @dev Returns the amount that can be invested now. The invested token
     * does not have to be the underlying token.
     * investable > 0 means it's time to call invest.
     */
    function investable() public view virtual override returns (uint256) {
        return IERC20Upgradeable(SBTCCRV).balanceOf(address(this));
    }

    /**
     * @dev Invest the underlying assets for additional yield.
     * Only governance or strategist can call this function.
     */
    function invest() public virtual override onlyStrategist {
        IERC20Upgradeable _token = IERC20Upgradeable(SBTCCRV);
        uint256 _balance = _token.balanceOf(address(this));
        if (_balance > 0) {
            _token.safeApprove(SBTCCRV_GAUGE, 0);
            _token.safeApprove(SBTCCRV_GAUGE, _balance);
            ICurveGauge(SBTCCRV_GAUGE).deposit(_balance);
        }
    }

    /**
     * @dev Returns the amount of reward that could be harvested now.
     * harvestable > 0 means it's time to call harvest.
     */
    function harvestable() public view virtual override returns (uint256) {
        return ICurveGauge(SBTCCRV_GAUGE).claimable_tokens(address(this));
    }

    /**
     * @dev Harvest additional yield from the investment.
     * Only governance or strategist can call this function.
     */
    function harvest() public virtual override onlyStrategist {
        // Claims CRV from Curve
        ICurveMinter(MINTER).mint(SBTCCRV_GAUGE);
        uint256 _crv = IERC20Upgradeable(CRV).balanceOf(address(this));

        // Uniswap: CRV --> WETH --> WBTC
        if (_crv > 0) {
            IERC20Upgradeable(CRV).safeApprove(UNISWAP, 0);
            IERC20Upgradeable(CRV).safeApprove(UNISWAP, _crv);

            address[] memory _path = new address[](3);
            _path[0] = CRV;
            _path[1] = WETH;
            _path[2] = WBTC;

            IUniswapRouter(UNISWAP).swapExactTokensForTokens(_crv, uint256(0), _path, address(this), block.timestamp.add(1800));
        }
        // Curve: WBTC --> renCRV
        uint256 _wbtc = IERC20Upgradeable(WBTC).balanceOf(address(this));
        if (_wbtc == 0) return;

        // If there is performance fee, charged in WBTC
        uint256 _fee = 0;
        if (performanceFee > 0) {
            _fee = _wbtc.mul(performanceFee).div(PERCENT_MAX);
            IERC20Upgradeable(WBTC).safeTransfer(treasury, _fee);
            _wbtc = _wbtc.sub(_fee);
        }

        IERC20Upgradeable(WBTC).safeApprove(SBTC_SWAP, 0);
        IERC20Upgradeable(WBTC).safeApprove(SBTC_SWAP, _wbtc);
        ICurveFi(SBTC_SWAP).add_liquidity([0, _wbtc, 0], 0);

        // Reinvest to get compound yield
        invest();
        // Also it's a good time to rebase!
        rebase();

        emit Harvested(SBTCCRV, _wbtc, _fee);
    }

    /**
     * @dev Checks whether a token can be salvaged via salvageToken(). The following two
     * tokens are not salvageable:
     * 1) sbtcCrv
     * 2) WBTC
     * 3) CRV
     * @param _token Token to check salvageability.
     */
    function _salvageable(address _token) internal view virtual override returns (bool) {
        return _token != SBTCCRV && _token != WBTC && _token != CRV;
    }

    /**
     * @dev Returns the amount of single plus token is worth for one underlying token, expressed in WAD.
     */
    function _conversionRate() internal view virtual override returns (uint256) {
        // Curve's LP virtual price is in WAD
        return ICurveFi(SBTC_SWAP).get_virtual_price();
    }

    /**
     * @dev Returns the total value of the underlying token in terms of the peg value, scaled to 18 decimals
     * and expressed in WAD.
     */
    function _totalUnderlyingInWad() internal view virtual override returns (uint256) {
        uint256 _balance = IERC20Upgradeable(SBTCCRV).balanceOf(address(this));
        _balance = _balance.add(ICurveGauge(SBTCCRV_GAUGE).balanceOf(address(this)));

        // Conversion rate is the amount of single plus token per underlying token, in WAD.
        return _balance.mul(_conversionRate());
    }

    /**
     * @dev Withdraws underlying tokens.
     * @param _receiver Address to receive the token withdraw.
     * @param _amount Amount of underlying token withdraw.
     */
    function _withdraw(address _receiver, uint256  _amount) internal virtual override {
        IERC20Upgradeable _token = IERC20Upgradeable(SBTCCRV);
        uint256 _balance = _token.balanceOf(address(this));
        if (_balance < _amount) {
            ICurveGauge(SBTCCRV_GAUGE).withdraw(_amount.sub(_balance));
            // In case of rounding errors
            _amount = MathUpgradeable.min(_amount, _token.balanceOf(address(this)));
        }
        _token.safeTransfer(_receiver, _amount);
    }
}
