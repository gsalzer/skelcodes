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

    // **** So we dont have to keep passing data through the functions ****

    // Stateful market maker params
    // routers:           Routers used for swapping (e.g. 1inch, Uniswap, Matcha)
    // routerCalldata:    Calldata contract has to use
    // constituents:      BDI constituents tokens (e.g. yvSNX, yvUNI, cCOMP...)
    // underlyings:       Underlyings of constituents (e.g. SNX, UNI, COMP...)
    // underlyingWeghts:  Weightings of the underlyings, (i.e. % they represent in BDI)
    //                    Should add up to 1e18
    struct MMParams {
        address[] routers;
        bytes[] routerCalldata;
        address[] constituents;
        address[] underlyings;
        uint256[] underlyingsWeights;
    }

    // **** Misc ****

    address constant SOLO = 0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e;

    // **** DeFi ****

    // Aave
    address constant LENDING_POOL_V1 = 0x398eC7346DcD622eDc5ae82352F02bE94C62d119;
    address constant LENDING_POOL_CORE_V1 = 0x3dfd23A6c5E8BbcFc9581d2E864a68feb6a076d3;

    // Curve
    address constant CURVE_LINK_POOL = 0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    // Compound
    address constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    // **** Tokens ****

    // Curve Tokens
    address constant linkCRV = 0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;
    address constant gaugeLinkCRV = 0xFD4D8a17df4C27c1dD245d153ccf4499e806C87D;

    // Router address
    address constant SUSHISWAP_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
    address constant SUSHISWAP_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    // Yearn
    address constant yvCurveLink = 0xf2db9a7c0ACd427A680D640F02d90f6186E71725;
    address constant yveCRV = 0xc5bDdf9843308380375a611c18B50Fb9341f502A;
    address constant yvBOOST = 0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a;
    address constant yvUNI = 0xFBEB78a723b8087fD2ea7Ef1afEc93d35E8Bed42;
    address constant yvYFI = 0xE14d13d8B3b85aF791b2AADD661cDBd5E6097Db1;
    address constant yvSNX = 0xF29AE508698bDeF169B89834F76704C3B205aedf;

    // CTokens
    address constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    // SUSHI
    address constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    // WETH
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // BDI
    address constant BDI = 0x0309c98B1bffA350bcb3F9fB9780970CA32a5060;
    address constant SUSHI_BDI_ETH = 0x8d782C5806607E9AAFB2AC38c1DA3838Edf8BD03;

    // Underlyings
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
    address constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

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

    /// @notice Converts a constituent to its underlying
    /// @param _constituent Derivate token address, if its the underlying it won't do anything
    /// @return Underlying address
    function _toUnderlying(address _constituent, uint256 _amount) internal returns (address, uint256) {
        if (_isCToken(_constituent)) {
            return _fromCToken(_constituent, _amount);
        }

        if (_isATokenV1(_constituent)) {
            return _fromATokenV1(_constituent, _amount);
        }

        if (_constituent == XSUSHI) {
            return _fromXSushi(_amount);
        }

        if (_constituent == linkCRV) {
            return _fromLinkCRV(_amount);
        }

        if (_constituent == gaugeLinkCRV) {
            (, uint256 amount) = _fromGaugeLinkCRV(_amount);
            return _fromLinkCRV(amount);
        }

        if (_constituent == yvCurveLink) {
            (, uint256 amount) = _fromYearnLinkCRV(_amount);
            return _fromLinkCRV(amount);
        }

        if (_constituent == yvBOOST || _constituent == yveCRV) {
            if (_constituent == yveCRV) {
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

        // Yearn
        if (_constituent == yvCurveLink || _constituent == yvUNI || _constituent == yvYFI || _constituent == yvSNX) {
            (address _yearnUnderlying, uint256 _yearnAmount) = _fromYearnV2Vault(_constituent, _amount);
            return _toUnderlying(_yearnUnderlying, _yearnAmount);
        }

        return (_constituent, _amount);
    }

    /// @notice Converts underlying to constituent
    /// @param  _constituent  Address of the constituent token
    function _toConstituent(address _underlying, address _constituent) internal {
        if (_underlying == _constituent) {
            return;
        }

        if (_isCToken(_constituent)) {
            _toCToken(_underlying);
        } else if (_isATokenV1(_constituent)) {
            _toATokenV1(_underlying);
        } else if (_constituent == XSUSHI) {
            _toXSushi();
        } else if (_underlying == LINK && _constituent == linkCRV) {
            _toLinkCRV();
        } else if (_underlying == LINK && _constituent == yvCurveLink) {
            _toLinkCRV();
            _toYearnLinkCRV();
        } else if (_underlying == LINK && _constituent == gaugeLinkCRV) {
            // Underlying should always be LINK
            // as we cannot get linkCRV on exchanges
            _toLinkCRV();
            _toGaugeLinkCRV();
        } else if (_underlying == CRV && _constituent == yveCRV) {
            // Underlying should always be CRV
            _toYveCRV();
        } else if (_underlying == CRV && _constituent == yvBOOST) {
            // Underlying should always be CRV
            _toYveCRV();
            _toYveBoost();
        } else if (_isYearnV2(_constituent)) {
            // This needs to be after yvCurveLink, yveCRV, and yvBoost
            // As they have a different conversion structure
            _toYearnV2Vault(_constituent);
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

    /// @notice Checks if a token is cToken
    /// @param  _vault Vault address
    /// @return Boolean value indicating if token is a cToken
    function _isYearnV2(address _vault) public pure returns (bool) {
        return (_vault == yvCurveLink || _vault == yvUNI || _vault == yvYFI || _vault == yvSNX);
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

        IERC20(LINK).safeApprove(CURVE_LINK_POOL, 0);
        IERC20(LINK).safeApprove(CURVE_LINK_POOL, balance);

        ICurveLINK(CURVE_LINK_POOL).add_liquidity([balance, uint256(0)], 0);
    }

    /// @notice Converts linkCRV to link
    function _fromLinkCRV(uint256 _lamount) internal returns (address, uint256) {
        uint256 _before = IERC20(LINK).balanceOf(address(this));
        ICurveLINK(CURVE_LINK_POOL).remove_liquidity_one_coin(_lamount, 0, 0);
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

    /// @notice Converts from linkCRV to yearnLinkCRV
    function _toYearnLinkCRV() internal {
        uint256 balance = IERC20(linkCRV).balanceOf(address(this));
        IERC20(linkCRV).safeApprove(yvCurveLink, 0);
        IERC20(linkCRV).safeApprove(yvCurveLink, balance);
        IYearn(yvCurveLink).deposit(balance);
    }

    /// @notice Converts from yearnLinkCRV to linkCRV
    function _fromYearnLinkCRV(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(linkCRV).balanceOf(address(this));
        IYearn(yvCurveLink).withdraw(_amount);
        uint256 _after = IERC20(linkCRV).balanceOf(address(this));
        return (linkCRV, _after.sub(_before));
    }

    /// @notice Converts from yveCRV to yvBOOST
    function _fromYveBoost(uint256 _amount) internal returns (address, uint256) {
        uint256 _before = IERC20(yveCRV).balanceOf(address(this));
        IYearn(yvBOOST).withdraw(_amount);
        uint256 _after = IERC20(yveCRV).balanceOf(address(this));
        return (yveCRV, _after.sub(_before));
    }

    /// @notice Converts to Yearn Vault
    function _toYearnV2Vault(address _vault) internal {
        address _underlying = IYearn(_vault).token();
        uint256 _amount = IERC20(_underlying).balanceOf(address(this));
        IERC20(_underlying).safeApprove(_vault, 0);
        IERC20(_underlying).safeApprove(_vault, _amount);
        IYearn(_vault).deposit();
    }

    /// @notice Converts from Yearn Vault
    function _fromYearnV2Vault(address _vault, uint256 _amount) internal returns (address, uint256) {
        address _underlying = IYearn(_vault).token();
        uint256 _before = IERC20(_underlying).balanceOf(address(this));
        IYearn(_vault).withdraw(_amount);
        uint256 _after = IERC20(_underlying).balanceOf(address(this));
        return (_underlying, _after.sub(_before));
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

    /// @notice Converts ETH into BDI
    function _mintBDIWithWETH(uint256 _wethAmount, bytes memory _mmData) internal returns (uint256) {
        MMParams memory mmParams = abi.decode(_mmData, (MMParams));

        // Convert them all to the underlyings
        uint256 bdpiToMint;

        // Get total amount in bdpi
        (, uint256[] memory tokenAmountsInBasket) = BDPI.getAssetsAndBalances();

        // BDPI total supply
        uint256 basketTotalSupply = BDPI.totalSupply();

        // How much WETH to send
        uint256 wethToSend;
        bool success;

        for (uint256 i = 0; i < mmParams.constituents.length; i++) {
            // Convert them from WETH to their respective tokens
            wethToSend = _wethAmount.mul(mmParams.underlyingsWeights[i]).div(1e18);

            IWETH(WETH).approve(mmParams.routers[i], wethToSend);
            (success, ) = mmParams.routers[i].call(mmParams.routerCalldata[i]);
            require(success, "!swap");

            // Convert to from respective token to constituent
            _toConstituent(mmParams.underlyings[i], mmParams.constituents[i]);

            // Approve constituent and calculate mint amount
            bdpiToMint = _approveConstituentAndGetMintAmount(
                mmParams.constituents[i],
                basketTotalSupply,
                tokenAmountsInBasket[i],
                bdpiToMint
            );
        }

        // Mint tokens
        BDPI.mint(bdpiToMint);

        return bdpiToMint;
    }

    /// @notice Approves constituent to the basket address and gets the mint amount.
    ///         Mainly here to avoid stack too deep errors
    /// @param  constituent  Address of the constituent (e.g. cUNI, aYFI)
    /// @param  basketTotalSupply  Total supply of the basket token
    /// @param  tokenAmountInBasket  Amount of constituent currently in the basket
    /// @param  curMintAmount  Accumulator - whats the minimum mint amount right now
    function _approveConstituentAndGetMintAmount(
        address constituent,
        uint256 basketTotalSupply,
        uint256 tokenAmountInBasket,
        uint256 curMintAmount
    ) internal returns (uint256) {
        uint256 constituentBal = IERC20(constituent).balanceOf(address(this));

        IERC20(constituent).safeApprove(address(BDPI), 0);
        IERC20(constituent).safeApprove(address(BDPI), constituentBal);

        // Calculate how much BDPI we can mint at max
        // Formula: min(e for e in bdpiSupply * tokenWeHave[e] / tokenInBDPI[e])
        if (curMintAmount == 0) {
            return basketTotalSupply.mul(constituentBal).div(tokenAmountInBasket);
        }

        uint256 temp = basketTotalSupply.mul(constituentBal).div(tokenAmountInBasket);
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
    function _burnBDIToWETH(uint256 _bdiAmount, bytes memory _mmData) internal returns (uint256) {
        MMParams memory mmParams = abi.decode(_mmData, (MMParams));

        (address[] memory underlyings, uint256[] memory underlyingAmounts) =
            _burnBDIAndGetUnderlyingAndAmounts(_bdiAmount);

        // Convert underlying to WETH
        bool success;
        for (uint256 i = 0; i < underlyings.length; i++) {
            // If we already have WETH then just skip it (e.g. yvBOOST or yveCRV)
            if (underlyings[i] != WETH && mmParams.routers[i] != address(0)) {
                IERC20(underlyings[i]).safeApprove(mmParams.routers[i], 0);
                IERC20(underlyings[i]).safeApprove(mmParams.routers[i], underlyingAmounts[i]);
                (success, ) = mmParams.routers[i].call(mmParams.routerCalldata[i]);
                require(success, "!swap");
            }
        }

        uint256 totalWETH = IERC20(WETH).balanceOf(address(this));
        return totalWETH;
    }

    function _burnBDIAndGetUnderlyingAndAmounts(uint256 _bdiAmount)
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
        IBasket(BDPI).burn(_bdiAmount);
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

