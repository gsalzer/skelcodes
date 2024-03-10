// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./IBasket.sol";
import "./IComptroller.sol";
import "./IERC20.sol";

import "./UniswapV3.sol";
import "./SocialZapperBase.sol";

import "./SafeERC20.sol";

contract SocialBDIBurner is SocialZapperBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal constant UNIV3_FACTORY = address(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address internal constant UNIV2_FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address internal constant SUSHI_FACTORY = address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);


    address internal constant BDI = address(0x0309c98B1bffA350bcb3F9fB9780970CA32a5060);

    address internal constant XSUSHI = 0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272;

    address internal constant COMPTROLLER = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

    address internal constant CUNI = 0x35A18000230DA775CAc24873d00Ff85BccdeD550;
    address internal constant CCOMP = 0x70e36f6BF80a52b3B46b3aF8e106CC0ed743E8e4;

    address internal constant CURVE_LINK_POOL = 0xF178C0b5Bb7e7aBF4e12A4838C7b7c5bA2C623c0;

    address internal constant linkCRV = 0xcee60cFa923170e4f8204AE08B4fA6A3F5656F3a;
    address internal constant yvCurveLink = 0xf2db9a7c0ACd427A680D640F02d90f6186E71725;
    address internal constant yvUNI = 0xFBEB78a723b8087fD2ea7Ef1afEc93d35E8Bed42;
    address internal constant yvYFI = 0xE14d13d8B3b85aF791b2AADD661cDBd5E6097Db1;
    address internal constant yvSNX = 0xF29AE508698bDeF169B89834F76704C3B205aedf;

    // Underlyings
    address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address internal constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address internal constant UNI = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
    address internal constant COMP = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    address internal constant YFI = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address internal constant SNX = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F;
    address internal constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address internal constant REN = 0x408e41876cCCDC0F92210600ef50372656052a38;
    address internal constant KNC = 0xdd974D5C2e2928deA5F71b9825b8b646686BD200;
    address internal constant LRC = 0xBBbbCA6A901c926F240b89EacB641d8Aec7AEafD;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address internal constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;
    address internal constant MTA = 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2;
    address internal constant SUSHI = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address internal constant ZRX = 0xE41d2489571d322189246DaFA5ebDe1F4699F498;

    struct SwapV3Calldata {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address[] targets;
        bytes[] data;
    }

    constructor(address _governance) SocialZapperBase(_governance, BDI) {
        // Approve all underlyings to bdi
        (address[] memory components, ) = IBasket(BDI).getOne();
        for (uint256 i = 0; i < components.length; i++) {
            IERC20(components[i]).safeApprove(BDI, type(uint256).max);
        }

        // Enter CCOMP and CUNI market on compound
        address[] memory markets = new address[](2);
        markets[0] = CCOMP;
        markets[1] = CUNI;
        IComptroller(COMPTROLLER).enterMarkets(markets);

        // Approve tokens
        IERC20(COMP).safeApprove(CCOMP, type(uint256).max);
        IERC20(UNI).safeApprove(CUNI, type(uint256).max);
        IERC20(UNI).safeApprove(yvUNI, type(uint256).max);
        IERC20(YFI).safeApprove(yvYFI, type(uint256).max);
        IERC20(SNX).safeApprove(yvSNX, type(uint256).max);
        IERC20(SUSHI).safeApprove(XSUSHI, type(uint256).max);
        IERC20(LINK).safeApprove(CURVE_LINK_POOL, type(uint256).max);
        IERC20(linkCRV).safeApprove(yvCurveLink, type(uint256).max);
    }

    function socialBurn(
        address[] memory targets,
        bytes[] memory data,
        uint256 _minRecv
    ) public onlyWeavers returns (uint256) {
        uint256 _before = IERC20(WETH).balanceOf(address(this));

        bool success;
        bytes memory m;
        for (uint256 i = 0; i < targets.length; i++) {
            (success, m) = targets[i].call(data[i]);
            require(success, string(m));
        }

        uint256 _after = IERC20(WETH).balanceOf(address(this));
        uint256 _wethRecv = _after.sub(_before);

        require(_wethRecv > _minRecv, "min-weth-recv");

        zapped[BDI][curId[BDI]] = _wethRecv;
        curId[BDI]++;

        return _wethRecv;
    }

    // UniswapV3 callback
    function uniswapV3SwapCallback(
        int256,
        int256,
        bytes calldata data
    ) external {
        SwapV3Calldata memory fsCalldata = abi.decode(data, (SwapV3Calldata));
        CallbackValidation.verifyCallback(UNIV3_FACTORY, fsCalldata.tokenIn, fsCalldata.tokenOut, fsCalldata.fee);

        bool success;
        bytes memory m;
        for (uint256 i = 0; i < fsCalldata.targets.length; i++) {
            (success, m) = fsCalldata.targets[i].call(fsCalldata.data[i]);
            require(success, string(m));
        }
    }

    /// @notice User withdraws converted Basket token
    function withdrawETH(address _token, uint256 _id) public {
        _withdrawZapped(WETH, _token, _id);
    }

    /// @notice User withdraws converted Basket token
    function withdrawETHMany(address[] memory _tokens, uint256[] memory _ids) public {
        _withdrawZappedMany(WETH, _tokens, _ids);
    }
}

