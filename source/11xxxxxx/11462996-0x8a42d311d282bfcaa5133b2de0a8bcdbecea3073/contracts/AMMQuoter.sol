pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IUniswapExchange.sol";
import "./interface/IUniswapFactory.sol";
import "./interface/IUniswapRouterV2.sol";
import "./interface/ICurveFi.sol";
import "./interface/IWeth.sol";
import "./interface/IPermanentStorage.sol";

contract AMMQuoter {
    using SafeMath for uint256;
    /* Constants */
    string public constant version = "5.0.0";
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    address public immutable UNISWAP_V2_ROUTER_02_ADDRESS;
    IPermanentStorage public immutable permStorage;

    event CurveTokenAdded(
        address indexed makerAddress,
        address indexed assetAddress,
        int128 index
    );

    constructor (IPermanentStorage _permStorage, address _uniswap_v2_router) public {
        permStorage = _permStorage;
        UNISWAP_V2_ROUTER_02_ADDRESS = _uniswap_v2_router;
    }
    function getMakerOutAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        address weth = permStorage.wethAddr();
        uint256 makerAssetAmount;
        int128 fromTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _takerAssetAddr);
        int128 toTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _makerAssetAddr);
        if (fromTokenCurveIndex != 0 || 
            toTokenCurveIndex != 0
        ) {
            ICurveFi curve = ICurveFi(_makerAddr);
            makerAssetAmount = curve.get_dy_underlying(fromTokenCurveIndex, toTokenCurveIndex, _takerAssetAmount).sub(1);
        } else if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
            address[] memory path = new address[](2);
            if (_takerAssetAddr == ZERO_ADDRESS || _takerAssetAddr == ETH_ADDRESS) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (_makerAssetAddr == ZERO_ADDRESS || _makerAssetAddr == ETH_ADDRESS) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsOut(_takerAssetAmount, path);
            makerAssetAmount = amounts[1];
        } else {
            revert("Unsupported makerAddress");
        }
        return makerAssetAmount;
    }

    function getBestOutAmount(
        address[] memory _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _takerAssetAmount
    )
        public
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 0;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 makerAssetAmount = getMakerOutAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _takerAssetAmount);
            if (makerAssetAmount > bestAmount) {
                bestAmount = makerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function getTakerInAmount(
        address _makerAddr,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        public
        view
        returns (uint256)
    {
        address weth = permStorage.wethAddr();
        uint256 takerAssetAmount;
        int128 fromTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _takerAssetAddr);
        int128 toTokenCurveIndex = permStorage.getCurveTokenIndex(_makerAddr, _makerAssetAddr);
        if (fromTokenCurveIndex != 0 || 
            toTokenCurveIndex != 0
        ) {
            ICurveFi curve = ICurveFi(_makerAddr);
            takerAssetAmount = curve.get_dy_underlying(toTokenCurveIndex, fromTokenCurveIndex, _makerAssetAmount);
        } else if (_makerAddr == UNISWAP_V2_ROUTER_02_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
            address[] memory path = new address[](2);
            if (_takerAssetAddr == ZERO_ADDRESS || _takerAssetAddr == ETH_ADDRESS) {
                path[0] = weth;
                path[1] = _makerAssetAddr;
            } else if (_makerAssetAddr == ZERO_ADDRESS || _makerAssetAddr == ETH_ADDRESS) {
                path[0] = _takerAssetAddr;
                path[1] = weth;
            } else {
                path[0] = _takerAssetAddr;
                path[1] = _makerAssetAddr;
            }
            uint256[] memory amounts = router.getAmountsIn(_makerAssetAmount, path);
            takerAssetAmount = amounts[0];
        } else {
            revert("Unsupported makerAddress");
        }
        return takerAssetAmount;
    }

    function getBestInAmount(
        address[] memory _makerAddresses,
        address _takerAssetAddr,
        address _makerAssetAddr,
        uint256 _makerAssetAmount
    )
        public
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 2**256 - 1;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 takerAssetAmount = getTakerInAmount(makerAddress, _takerAssetAddr, _makerAssetAddr, _makerAssetAmount);
            if (takerAssetAmount < bestAmount) {
                bestAmount = takerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }
}
