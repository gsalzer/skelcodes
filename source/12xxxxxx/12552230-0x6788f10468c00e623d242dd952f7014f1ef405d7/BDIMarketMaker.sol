// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

import "./IBasket.sol";
import "./IATokenV1.sol";
import "./IUniswapV2.sol";
import "./IComptroller.sol";
import "./ISushiBar.sol";
import "./ICToken.sol";
import "./ICurve.sol";
import "./ILendingPoolV1.sol";
import "./IWETH.sol";
import "./IYearn.sol";

import "./console.sol";

contract MarketMakerHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Curve
    address constant CURVE_LINK = 0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    // Yearn tokens
    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;

    // Curve Tokens
    address constant linkCRV = 0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;
    address constant gaugeLinkCRV = 0xFD4D8a17df4C27c1dD245d153ccf4499e806C87D;

    // Compound
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // Router address
    address constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
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

    // BDI
    address constant BDI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;
    address constant SUSHI_BDI_ETH = 0x8d782C5806607E9AAFB2AC38c1DA3838Edf8BD03;

    // Defi tokens
    address constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
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

    // ATokens v1
    address constant AYFIv1 = 0x12e51E77DAAA58aA0E9247db7510Ea4B46F9bEAd;
    address constant ASNXv1 = 0x328C4c80BC7aCa0834Db37e6600A6c49E12Da4DE;
    address constant AMKRv1 = 0x7deB5e830be29F91E298ba5FF1356BB7f8146998;
    address constant ARENv1 = 0x69948cC03f478B95283F7dbf1CE764d0fc7EC54C;
    address constant AKNCv1 = 0x9D91BE44C06d373a8a226E1f3b146956083803eB;

    // BDPI
    IBasket constant BDPI = IBasket(0x0309c98B1bffA350bcb3F9fB9780970CA32a5060);

    /// @notice Enters Compound market. *Must be called before toCToken*
    /// @param  _markets  Compound markets to enter (underlying, not cTokens)
    function enterMarkets(address[] memory _markets) public {
        IComptroller(COMPTROLLER).enterMarkets(_markets);
    }

    // **** Internal ****

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

        if (_derivative == linkCRV) {
            return _fromLinkCRV(_amount);
        }

        if (_derivative == gaugeLinkCRV) {
            (, uint256 amount) = _fromGaugeLinkCRV(_amount);
            return _fromLinkCRV(amount);
        }

        if (_derivative == yvBOOST || _derivative == yveCRV) {
            if (_derivative == yveCRV) {
                _toYveBoost();
            }

            // Just sell directly on uniswap
            address[] memory path = new address[](2);
            path[0] = yvBOOST;
            path[1] = WETH;

            uint256 _bamount = IERC20(yvBOOST).balanceOf(address(this));

            IERC20(yvBOOST).approve(SUSHISWAP_ROUTER, _bamount);
            uint256[] memory outs =
                IUniswapV2Router02(SUSHISWAP_ROUTER).swapExactTokensForTokens(
                    _bamount,
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );

            return (WETH, outs[1]);
        }

        return (_derivative, _amount);
    }

    /// @notice Converts underlying to derivative
    /// @param  _derivative  Address of the derivative token
    function _toDerivative(address _underlying, address _derivative) internal {
        if (_underlying == _derivative) {
            return;
        }

        if (_isCToken(_derivative)) {
            _toCToken(_underlying);
        } else if (_isATokenV1(_derivative)) {
            _toATokenV1(_underlying);
        } else if (_derivative == XSUSHI) {
            _toXSushi();
        } else if (_underlying == LINK && _derivative == linkCRV) {
            _toLinkCRV();
        } else if (_underlying == LINK && _derivative == gaugeLinkCRV) {
            // Underlying should always be LINK
            // as we cannot get linkCRV on exchanges
            _toLinkCRV();
            _toGaugeLinkCRV();
        } else if (_underlying == CRV && _derivative == yveCRV) {
            // Underlying should always be CRV
            _toYveCRV();
        } else if (_underlying == CRV && _derivative == yvBOOST) {
            // Underlying should always be CRV
            _toYveCRV();
            _toYveBoost();
        }
    }

    /// @notice Checks if a token is aTokenV1
    /// @param  _atoken Token address
    /// @return Boolean value indicating if token is an aTokenV1
    function _isATokenV1(address _atoken) public pure returns (bool) {
        return (_atoken == AYFIv1 || _atoken == ASNXv1 || _atoken == AMKRv1 || _atoken == ARENv1 || _atoken == AKNCv1);
    }

    /// @notice Checks if a token is cToken
    /// @param  _ctoken Token address
    /// @return Boolean value indicating if token is a cToken
    function _isCToken(address _ctoken) public pure returns (bool) {
        return (_ctoken == CCOMP || _ctoken == CUNI);
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

    /// @notice Redeems assets from the Aave market
    /// @param  _atoken  AToken to redeem from Aave
    function _fromATokenV1(address _atoken, uint256 _aamount) internal returns (address _token, uint256 _amount) {
        _token = IATokenV1(_atoken).underlyingAssetAddress();

        uint256 before = IERC20(_token).balanceOf(address(this));
        IATokenV1(_atoken).redeem(_aamount);
        _amount = IERC20(_token).balanceOf(address(this)).sub(before);
    }

    /// @notice Converts link to linkCRV
    function _toLinkCRV() internal {
        // Deposit into gauge
        uint256 balance = IERC20(LINK).balanceOf(address(this));

        IERC20(LINK).safeApprove(CURVE_LINK, 0);
        IERC20(LINK).safeApprove(CURVE_LINK, balance);

        ICurveLINK(CURVE_LINK).add_liquidity([balance, uint256(0)], 0);
    }

    /// @notice Converts linkCRV to link
    function _fromLinkCRV(uint256 _lamount) internal returns (address, uint256) {
        uint256 _before = IERC20(LINK).balanceOf(address(this));
        ICurveLINK(CURVE_LINK).remove_liquidity_one_coin(_lamount, 0, 0);
        uint256 _after = IERC20(LINK).balanceOf(address(this));
        return (LINK, _after.sub(_before));
    }

    /// @notice Converts linkCRV to GaugeLinkCRV
    function _toGaugeLinkCRV() internal {
        // Deposit into gauge
        uint256 balance = IERC20(linkCRV).balanceOf(address(this));
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, 0);
        IERC20(linkCRV).safeApprove(gaugeLinkCRV, balance);
        ILinkGauge(gaugeLinkCRV).deposit(balance);
    }

    /// @notice Converts GaugeLinkCRV to linkCRV
    function _fromGaugeLinkCRV(uint256 _amount) internal returns (address, uint256) {
        // Deposit into gauge
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        ILinkGauge(gaugeLinkCRV).withdraw(_amount);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts from crv to yveCRV
    function _toYveCRV() internal {
        uint256 balance = IERC20(CRV).balanceOf(address(this));
        IERC20(CRV).safeApprove(yveCRV, 0);
        IERC20(CRV).safeApprove(yveCRV, balance);
        IveCurveVault(yveCRV).deposit(balance);
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _toYveBoost() internal {
        uint256 balance = IERC20(yveCRV).balanceOf(address(this));
        IERC20(yveCRV).safeApprove(yvBOOST, 0);
        IERC20(yveCRV).safeApprove(yvBOOST, balance);
        IYearn(yvBOOST).deposit(balance);
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _fromYveBoost(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yveCRV).balanceOf(address(this));
        IYearn(yvBOOST).withdraw(_amount);
        uint256 _after = IERC20(yveCRV).balanceOf(address(this));
        return (yveCRV, _after.sub(_before));
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

    /// @notice Goes from xsushi to sushi
    function _fromXSushi(uint256 _xsushiAmount) internal returns (address, uint256) {
        uint256 before = IERC20(SUSHI).balanceOf(address(this));
        ISushiBar(XSUSHI).leave(_xsushiAmount);
        uint256 delta = IERC20(SUSHI).balanceOf(address(this)).sub(before);
        return (SUSHI, delta);
    }
}

contract MarketMakerMinter is MarketMakerHelpers {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /// @notice Converts ETH into a Basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasket  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasket  How much 1 basket token is worth in ETH
    /// @param  minMintAmount Minimum amount of basket token to mint
    /// @param  deadline      Deadline to mint by
    function _mintWithWETH(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasket,
        uint256 ethPerBasket,
        uint256 minMintAmount,
        uint256 deadline
    ) internal returns (uint256) {
        require(block.timestamp <= deadline, "expired");

        // BDPI to mint
        uint256 bdpiToMint =
            _convertETHToDerivativeAndGetMintAmount(
                routers,
                derivatives,
                underlyings,
                underlyingsInEthPerBasket,
                ethPerBasket
            );

        require(bdpiToMint >= minMintAmount, "!mint-min-amount");

        // Mint tokens
        BDPI.mint(bdpiToMint);

        return bdpiToMint;
    }

    /// @notice Converts ETH into the specific derivative and get mint amount for basket
    /// @param  derivatives  Address of the derivatives (e.g. cUNI, aYFI)
    /// @param  underlyings  Address of the underlyings (e.g. UNI,   YFI)
    /// @param  underlyingsInEthPerBasketToken  Off-chain calculation - how much each underlying is
    ///                                    worth in ETH per 1 unit of basket token
    /// @param  ethPerBasketToken  How much 1 basket token is worth in ETH
    function _convertETHToDerivativeAndGetMintAmount(
        address[] memory routers,
        address[] memory derivatives,
        address[] memory underlyings,
        uint256[] memory underlyingsInEthPerBasketToken,
        uint256 ethPerBasketToken
    ) internal returns (uint256) {
        // Path
        address[] memory path = new address[](2);
        path[0] = WETH;

        // Convert them all to the underlyings
        uint256 bdpiToMint;

        // Get total amount in bdpi
        (, uint256[] memory tokenAmountsInBasket) = BDPI.getAssetsAndBalances();

        // BDPI total supply
        uint256 basketTotalSupply = BDPI.totalSupply();

        uint256 ethAmount = IERC20(WETH).balanceOf(address(this));

        {
            uint256 ratio;
            uint256 ethToSend;
            for (uint256 i = 0; i < derivatives.length; i++) {
                ratio = underlyingsInEthPerBasketToken[i].mul(1e18).div(ethPerBasketToken);

                // Convert them from ETH to their respective tokens (truncate 1e4 for rounding errors)
                ethToSend = ethAmount.mul(ratio).div(1e24).mul(1e6);

                path[1] = underlyings[i];
                IUniswapV2Router02(routers[i]).swapExactTokensForTokens(
                    ethToSend,
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );

                // Convert to from respective token to derivative
                _toDerivative(underlyings[i], derivatives[i]);

                // Approve derivative and calculate mint amount
                bdpiToMint = _approveDerivativeAndGetMintAmount(
                    derivatives[i],
                    basketTotalSupply,
                    tokenAmountsInBasket[i],
                    bdpiToMint
                );
            }
        }

        return bdpiToMint;
    }

    /// @notice Approves derivative to the basket address and gets the mint amount.
    ///         Mainly here to avoid stack too deep errors
    /// @param  derivative  Address of the derivative (e.g. cUNI, aYFI)
    /// @param  basketTotalSupply  Total supply of the basket token
    /// @param  tokenAmountInBasket  Amount of derivative currently in the basket
    /// @param  curMintAmount  Accumulator - whats the minimum mint amount right now
    function _approveDerivativeAndGetMintAmount(
        address derivative,
        uint256 basketTotalSupply,
        uint256 tokenAmountInBasket,
        uint256 curMintAmount
    ) internal returns (uint256) {
        uint256 derivativeBal = IERC20(derivative).balanceOf(address(this));

        IERC20(derivative).safeApprove(address(BDPI), 0);
        IERC20(derivative).safeApprove(address(BDPI), derivativeBal);

        // Calculate how much BDPI we can mint at max
        // Formula: min(e for e in bdpiSupply * tokenWeHave[e] / tokenInBDPI[e])
        if (curMintAmount == 0) {
            return basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        }

        uint256 temp = basketTotalSupply.mul(derivativeBal).div(tokenAmountInBasket);
        if (temp < curMintAmount) {
            return temp;
        }

        return curMintAmount;
    }
}

contract MarketMakerBurner is MarketMakerHelpers {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // **** Internals **** //

    // Burns BDPI to ETH
    function _burnToWETH(address[] memory routers, uint256 _minETHAmount) internal returns (uint256) {
        uint256 amount = IERC20(address(BDPI)).balanceOf(address(this));

        (address[] memory underlyings, uint256[] memory underlyingAmounts) =
            _burnBDPIAndGetUnderlyingAndAmounts(amount);

        // Convert underlying to WETH
        address[] memory path = new address[](2);
        path[1] = WETH;
        for (uint256 i = 0; i < underlyings.length; i++) {
            // If we already have WETH (e.g. yvBOOST or yveCRV)
            if (underlyings[i] != WETH) {
                path[0] = underlyings[i];

                IERC20(underlyings[i]).safeApprove(routers[i], 0);
                IERC20(underlyings[i]).safeApprove(routers[i], underlyingAmounts[i]);
                IUniswapV2Router02(routers[i]).swapExactTokensForTokens(
                    underlyingAmounts[i],
                    0,
                    path,
                    address(this),
                    block.timestamp + 60
                );
            }
        }
        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));
        require(totalWETH >= _minETHAmount, "!min-eth-amount");

        return totalWETH;
    }

    function _burnBDPIAndGetUnderlyingAndAmounts(uint256 _amount)
        internal
        returns (address[] memory, uint256[] memory)
    {
        (address[] memory assets, ) = IBasket(BDPI).getAssetsAndBalances();
        uint256[] memory deltas = new uint256[](assets.length);
        address[] memory underlyings = new address[](assets.length);
        uint256[] memory underlyingAmounts = new uint256[](assets.length);

        address underlying;
        uint256 underlyingAmount;

        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this));
        }
        IBasket(BDPI).burn(_amount);
        for (uint256 i = 0; i < assets.length; i++) {
            deltas[i] = IERC20(assets[i]).balanceOf(address(this)).sub(deltas[i]);

            (underlying, underlyingAmount) = _toUnderlying(assets[i], deltas[i]);

            underlyings[i] = underlying;
            underlyingAmounts[i] = underlyingAmount;
        }

        return (underlyings, underlyingAmounts);
    }
}

contract BDIMarketMaker is MarketMakerBurner, MarketMakerMinter {
    receive() external payable {}
}

