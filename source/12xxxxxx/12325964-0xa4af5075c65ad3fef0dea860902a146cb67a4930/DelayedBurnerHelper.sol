// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./IUniswapV2.sol";
import "./ILendingPoolV1.sol";
import "./ICompoundLens.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract DelayedBurnerHelper {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Exchanges
    address constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    // Tokens
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant BASK = 0x44564d0bd94343f72E3C8a0D22308B7Fa71DB0Bb;
    address constant XBASK = 0x5C0e75EB4b27b5F9c99D78Fc96AFf7869eDa007b;
    address constant BDPI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Compound
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // Sushi
    address constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // CTokens
    address constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // ATokens v1
    address constant AYFIv1 = 0x12e51E77DAAA58aA0E9247db7510Ea4B46F9bEAd;
    address constant ASNXv1 = 0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE;
    address constant AMKRv1 = 0x7deB5e830be29F91E298ba5FF1356BB7f8146998;
    address constant ARENv1 = 0x69948cC03f478B95283F7dbf1CE764d0fc7EC54C;
    address constant AKNCv1 = 0x9D91BE44C06d373a8a226E1f3b146956083803eB;

    // Underlying
    address constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    address constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;

    /// @notice Enters Compound market. *Must be called before toCToken*
    /// @param  _markets  Compound markets to enter (underlying, not cTokens)
    function enterMarkets(address[] memory _markets) external {
        IComptroller(COMPTROLLER).enterMarkets(_markets);
    }

    // **** Internal functions ****

    /// @notice Converts a derivative to its underlying
    /// @param _derivative Derivate token address, if its the underlying it won't do anything
    /// @return Underlying address
    function _toUnderlying(address _derivative, uint256 _amount) internal returns (address, uint256) {
        if (_isCToken(_derivative)) {
            return _fromCToken(_derivative, _amount);
        }

        if (_isATokenV1(_derivative)) {
            return _fromATokenV1(_derivative, _amount);
        }

        if (_derivative == XSUSHI) {
            return _fromXSushi(_amount);
        }

        return (_derivative, _amount);
    }

    /// @notice Checks if a token is cToken
    /// @param  _ctoken Token address
    /// @return Boolean value indicating if token is a cToken
    function _isCToken(address _ctoken) public pure returns (bool) {
        return (_ctoken == CCOMP || _ctoken == CUNI);
    }

    /// @notice Checks if a token is aTokenV1
    /// @param  _atoken Token address
    /// @return Boolean value indicating if token is an aTokenV1
    function _isATokenV1(address _atoken) public pure returns (bool) {
        return (_atoken == AYFIv1 || _atoken == ASNXv1 || _atoken == AMKRv1 || _atoken == ARENv1 || _atoken == AKNCv1);
    }

    /// @notice Redeems assets from the Compound market
    /// @param  _ctoken  CToken to redeem from Compound
    function _fromCToken(address _ctoken, uint256 _camount) internal returns (address _token, uint256 _amount) {
        // Only doing CUNI or CCOMP
        require(_ctoken == CUNI || _ctoken == CCOMP, "!valid-from-ctoken");

        _token = ICToken(_ctoken).underlying();

        uint256 before = IERC20(_token).balanceOf(address(this));
        require(ICToken(_ctoken).redeem(_camount) == 0, "!ctoken-redeem");
        _amount = IERC20(_token).balanceOf(address(this)).sub(before);
    }

    /// @notice Redeems assets from the Aave market
    /// @param  _atoken  AToken to redeem from Aave
    function _fromATokenV1(address _atoken, uint256 _aamount) internal returns (address _token, uint256 _amount) {
        _token = IATokenV1(_atoken).underlyingAssetAddress();

        uint256 before = IERC20(_token).balanceOf(address(this));
        IATokenV1(_atoken).redeem(_aamount);
        _amount = IERC20(_token).balanceOf(address(this)).sub(before);
    }

    /// @notice Goes from xsushi to sushi
    function _fromXSushi(uint256 _xsushiAmount) internal returns (address, uint256) {
        uint256 before = IERC20(SUSHI).balanceOf(address(this));
        ISushiBar(XSUSHI).leave(_xsushiAmount);
        uint256 delta = IERC20(SUSHI).balanceOf(address(this)).sub(before);
        return (SUSHI, delta);
    }

    // Swaps tokens on either uniswap / sushiswap
    function _swap(
        address fromToken,
        address toToken,
        uint256 amountIn,
        address to
    ) internal returns (uint256 amountOut) {
        // Checks
        // X1 - X5: OK
        IUniswapV2Pair pair =
            IUniswapV2Pair(IUniswapV2Factory(_getFactoryFor(fromToken, toToken)).getPair(fromToken, toToken));
        require(address(pair) != address(0), "BaskMaker: Cannot convert");

        // Interactions
        // X1 - X5: OK
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountInWithFee = amountIn.mul(997);
        if (fromToken == pair.token0()) {
            amountOut = amountIn.mul(997).mul(reserve1) / reserve0.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(0, amountOut, to, new bytes(0));
            // TODO: Add maximum slippage?
        } else {
            amountOut = amountIn.mul(997).mul(reserve0) / reserve1.mul(1000).add(amountInWithFee);
            IERC20(fromToken).safeTransfer(address(pair), amountIn);
            pair.swap(amountOut, 0, to, new bytes(0));
            // TODO: Add maximum slippage?
        }
    }

    function _getFactoryFor(address from, address to) internal pure returns (address) {
        if (to == WETH) {
            if (from == KNC || from == LRC || from == BAL || from == MTA) {
                return UNIV2_FACTORY;
            }
        }

        return SUSHI_FACTORY;
    }
}

