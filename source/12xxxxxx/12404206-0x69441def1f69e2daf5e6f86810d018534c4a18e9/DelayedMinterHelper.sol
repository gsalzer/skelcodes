// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

import "./IATokenV1.sol";
import "./ICToken.sol";
import "./IComptroller.sol";
import "./ILendingPoolV1.sol";
import "./ISushiBar.sol";

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract DelayedMinterHelper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Compound
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // Router address
    address constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // CTokens
    address constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // SUSHI
    address constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // WETH
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // DPI
    address constant DPI = 0x1494CA1F11D487c2bBe4543E90080AeBa4BA3C2b;

    // Defi tokens
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

    // **** Public ****

    /// @notice Enters Compound market. *Must be called before toCToken*
    /// @param  _markets  Compound markets to enter (underlying, not cTokens)
    function enterMarkets(address[] memory _markets) public {
        IComptroller(COMPTROLLER).enterMarkets(_markets);
    }

    // **** Internal ****

    /// @notice Converts underlying to derivative
    /// @param  _derivative  Address of the derivative token
    function _toDerivative(address _underlying, address _derivative) internal {
        if (_underlying == _derivative) {
            return;
        }

        if (_derivative == CUNI || _derivative == CCOMP) {
            _toCToken(_underlying);
        } else if (_derivative == XSUSHI) {
            _toXSushi();
        } else {
            _toATokenV1(_underlying);
        }
    }

    /// @notice Supplies assets to the Compound market
    /// @param  _token  Underlying token to supply to Compound
    function _toCToken(address _token) internal {
        // Only doing UNI or COMP for CTokens
        require(_token == UNI || _token == COMP, "!valid-to-ctoken");

        address _ctoken = _getTokenToCToken(_token);
        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(_ctoken, 0);
        IERC20(_token).safeApprove(_ctoken, balance);
        require(ICToken(_ctoken).mint(balance) == 0, "!ctoken-mint");
    }

    /// @notice Supplies assets to the Aave market
    /// @param  _token  Underlying to supply to Aave
    function _toATokenV1(address _token) internal {
        require(_token != UNI && _token != COMP, "no-uni-or-comp");

        uint256 balance = IERC20(_token).balanceOf(address(this));

        require(balance > 0, "!token-bal");

        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, 0);
        IERC20(_token).safeApprove(LENDING_POOL_CORE_V1, balance);
        ILendingPoolV1(LENDING_POOL_V1).deposit(_token, balance, 0);
    }

    /// @dev Token to CToken mapping
    /// @param  _token Token address
    function _getTokenToCToken(address _token) internal pure returns (address) {
        if (_token == UNI) {
            return CUNI;
        }
        if (_token == COMP) {
            return CCOMP;
        }
        revert("!supported-token-to-ctoken");
    }

    /// @notice Converts sushi to xsushi
    function _toXSushi() internal {
        uint256 balance = IERC20(SUSHI).balanceOf(address(this));
        require(balance > 0, "!sushi-bal");

        IERC20(SUSHI).safeApprove(XSUSHI, 0);
        IERC20(SUSHI).safeApprove(XSUSHI, balance);
        ISushiBar(XSUSHI).enter(balance);
    }
}

