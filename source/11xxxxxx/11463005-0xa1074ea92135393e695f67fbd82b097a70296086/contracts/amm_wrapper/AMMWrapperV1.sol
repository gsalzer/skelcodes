pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interface/IUniswapExchange.sol";
import "../interface/IUniswapFactory.sol";
import "../interface/IUniswapRouterV2.sol";
import "../interface/ICurveFi.sol";
import "../interface/IAMMV1.sol";
import "../interface/IWeth.sol";

contract AMMWrapperV1 is
    IAMMV1,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;

    address public constant UNISWAP_V1_FACTORY_ADDRESS = 0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95;
    address public constant UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);

    IWETH constant internal weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    event Swapped(
        address spender,
        address fromAssetAddress,
        address toAssetAddress,
        uint256 takerAssetAmount,
        uint256 makerAssetAmount
    );

    receive() external payable {}

    function getMakerOutAmount(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount
    )
        override
        public
        view
        returns (uint256)
    {
        uint256 makerAssetAmount;
        if (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS) {
            IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
            if (_fromAssetAddress == ZERO_ADDRESS || _fromAssetAddress == ETH_ADDRESS) {
                IUniswapExchange exchange = IUniswapExchange(factory.getExchange(_toAssetAddress));
                makerAssetAmount = exchange.getEthToTokenInputPrice(_takerAssetAmount);
            } else if (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS) {
                IUniswapExchange exchange = IUniswapExchange(factory.getExchange(_fromAssetAddress));
                makerAssetAmount = exchange.getTokenToEthInputPrice(_takerAssetAmount);
            } else {
                IUniswapExchange fromExchange = IUniswapExchange(factory.getExchange(_fromAssetAddress));
                IUniswapExchange toExchange = IUniswapExchange(factory.getExchange(_toAssetAddress));
                uint256 ethAmount = fromExchange.getTokenToEthInputPrice(_takerAssetAmount);
                makerAssetAmount = toExchange.getEthToTokenInputPrice(ethAmount);
            }
        } else if (_makerAddress == UNISWAP_V2_ROUTER_02_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
            address[] memory path = new address[](2);
            if (_fromAssetAddress == ZERO_ADDRESS || _fromAssetAddress == ETH_ADDRESS) {
                path[0] = address(weth);
                path[1] = _toAssetAddress;
            } else if (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS) {
                path[0] = _fromAssetAddress;
                path[1] = address(weth);
            } else {
                path[0] = _fromAssetAddress;
                path[1] = _toAssetAddress;
            }
            uint256[] memory amounts = router.getAmountsOut(_takerAssetAmount, path);
            makerAssetAmount = amounts[1];
        } else {
            revert("AMMWrapperV1: Unsupported makerAddress");
        }
        return makerAssetAmount;
    }

    function getBestOutAmount(
        address[] memory _makerAddresses,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount
    )
        override
        public
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 0;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 makerAssetAmount = getMakerOutAmount(makerAddress, _fromAssetAddress, _toAssetAddress, _takerAssetAmount);
            if (makerAssetAmount > bestAmount) {
                bestAmount = makerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function getTakerInAmount(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _makerAssetAmount
    )
        override
        public
        view
        returns (uint256)
    {
        uint256 takerAssetAmount;
        if (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS) {
            IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
            if (_fromAssetAddress == ZERO_ADDRESS || _fromAssetAddress == ETH_ADDRESS) {
                IUniswapExchange exchange = IUniswapExchange(factory.getExchange(_toAssetAddress));
                takerAssetAmount = exchange.getEthToTokenOutputPrice(_makerAssetAmount);
            } else if (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS) {
                IUniswapExchange exchange = IUniswapExchange(factory.getExchange(_fromAssetAddress));
                takerAssetAmount = exchange.getTokenToEthOutputPrice(_makerAssetAmount);
            } else {
                IUniswapExchange fromExchange = IUniswapExchange(factory.getExchange(_fromAssetAddress));
                IUniswapExchange toExchange = IUniswapExchange(factory.getExchange(_toAssetAddress));
                uint256 ethAmount = toExchange.getEthToTokenOutputPrice(_makerAssetAmount);
                takerAssetAmount = fromExchange.getTokenToEthOutputPrice(ethAmount);
            }
        } else if (_makerAddress == UNISWAP_V2_ROUTER_02_ADDRESS) {
            IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
            address[] memory path = new address[](2);
            if (_fromAssetAddress == ZERO_ADDRESS || _fromAssetAddress == ETH_ADDRESS) {
                path[0] = address(weth);
                path[1] = _toAssetAddress;
            } else if (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS) {
                path[0] = _fromAssetAddress;
                path[1] = address(weth);
            } else {
                path[0] = _fromAssetAddress;
                path[1] = _toAssetAddress;
            }
            uint256[] memory amounts = router.getAmountsIn(_makerAssetAmount, path);
            takerAssetAmount = amounts[0];
        } else {
            revert("AMMWrapperV1: Unsupported makerAddress");
        }
        return takerAssetAmount;
    }

    function getBestInAmount(
        address[] memory _makerAddresses,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _makerAssetAmount
    )
        override
        public
        view
        returns (address bestMaker, uint256 bestAmount)
    {
        bestAmount = 2**256 - 1;
        uint256 poolLength = _makerAddresses.length;
        for (uint256 i = 0; i < poolLength; i++) {
            address makerAddress = _makerAddresses[i];
            uint256 takerAssetAmount = getTakerInAmount(makerAddress, _fromAssetAddress, _toAssetAddress, _makerAssetAmount);
            if (takerAssetAmount < bestAmount) {
                bestAmount = takerAssetAmount;
                bestMaker = makerAddress;
            }
        }
        return (bestMaker, bestAmount);
    }

    function trade(
        address _makerAddress,
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        address _spender,
        uint256 deadline
    )
        override
        payable
        external
        nonReentrant
        returns (uint256) 
    {
        address fromAssetInternalAddress = _fromAssetAddress;
        address toAssetInternalAddress = _toAssetAddress;
        IERC20 fromAssetInternal = IERC20(_fromAssetAddress);
        address targetContract = _makerAddress;

        if (_fromAssetAddress == ZERO_ADDRESS ||
            _fromAssetAddress == ETH_ADDRESS) {    
            require(msg.value > 0, "AMMWrapperV1: msg.value is zero");
            require(_takerAssetAmount == msg.value, "AMMWrapperV1: msg.value doesn't match");
        }

        // Transfer asset from user and deposit to weth if needed
        if (_makerAddress != UNISWAP_V1_FACTORY_ADDRESS &&
            (_fromAssetAddress == ZERO_ADDRESS ||
            _fromAssetAddress == ETH_ADDRESS) ) {
            // Deposit ETH to weth
            weth.deposit{value: msg.value}();
            fromAssetInternalAddress = address(weth);
            fromAssetInternal = IERC20(fromAssetInternalAddress);
        }   else if (_fromAssetAddress != ZERO_ADDRESS &&
                    _fromAssetAddress != ETH_ADDRESS) {
            // Transfer token from user
            fromAssetInternal.safeTransferFrom(_spender, address(this), _takerAssetAmount);
        }

        // Replace _toAssetAddress to weth if it's ZERO_ADDRESS or ETH_ADDRESS
        if (_makerAddress != UNISWAP_V1_FACTORY_ADDRESS &&
            (_toAssetAddress == ZERO_ADDRESS ||
            _toAssetAddress == ETH_ADDRESS)) {
            toAssetInternalAddress = address(weth);
        }

        // Approve
        if (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS) {
            IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
            targetContract = factory.getExchange(_fromAssetAddress);
        }

        if (_makerAddress != UNISWAP_V1_FACTORY_ADDRESS ||
            (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS && (_fromAssetAddress != ZERO_ADDRESS && _fromAssetAddress != ETH_ADDRESS))
        ) {
            fromAssetInternal.safeIncreaseAllowance(targetContract, _takerAssetAmount);
        }

        // Swap
        if (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS) {
            _tradeUniswapV1(_fromAssetAddress, _toAssetAddress, _takerAssetAmount, _makerAssetAmount, deadline);
        } else if (_makerAddress == UNISWAP_V2_ROUTER_02_ADDRESS) {
            _tradeUniswapV2TokenToToken(fromAssetInternalAddress, toAssetInternalAddress, _takerAssetAmount, _makerAssetAmount, deadline);
        } else {
            revert("AMMWrapperV1: Unsupported makerAddress");
        }

        // Close allowance
        if (_makerAddress != UNISWAP_V1_FACTORY_ADDRESS ||
            (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS && (_fromAssetAddress != ZERO_ADDRESS && _fromAssetAddress != ETH_ADDRESS))
        ) {
            fromAssetInternal.safeApprove(targetContract, 0);
        }

        // Send back assets to spender
        uint256 makerAssetAmount = _sendBackAssets(_makerAddress, _toAssetAddress, _makerAssetAmount, _spender);
        emit Swapped(_spender, _fromAssetAddress, _toAssetAddress, _takerAssetAmount, makerAssetAmount);
        return makerAssetAmount;
    }

    function _tradeUniswapV1(
        address _fromAssetAddress,
        address _toAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 deadline
    )
        internal 
        returns (uint256) 
    {
        uint256 amount = 0;
        if (_fromAssetAddress == ZERO_ADDRESS ||
            _fromAssetAddress == ETH_ADDRESS) {
            amount = _tradeUniswapV1EthToToken(_toAssetAddress, _makerAssetAmount, deadline);
        } else if (_toAssetAddress == ZERO_ADDRESS ||
                    _toAssetAddress == ETH_ADDRESS) {
            amount =_tradeUniswapV1TokenToEth(_fromAssetAddress, _takerAssetAmount, _makerAssetAmount, deadline);
        } else {
            amount = _tradeUniswapV1TokenToToken(_fromAssetAddress, _toAssetAddress, _takerAssetAmount, _makerAssetAmount, deadline);
        }
        return amount;
    }

    function _sendBackAssets(
        address _makerAddress,
        address _toAssetAddress,
        uint256 _makerAssetAmount,
        address _spender
    )
        internal
        returns (uint256)
    {
        uint256 makerAssetAmount = 0;
        if (_makerAddress == UNISWAP_V1_FACTORY_ADDRESS &&
            (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS)) {
            makerAssetAmount = address(this).balance;
            require(makerAssetAmount >= _makerAssetAmount, "AMMWrapperV1: insufficient ETH");
            // TODO: review the amount of gas provision
            (bool success, ) = _spender.call{ gas: 30000, value: makerAssetAmount }("");
            require(success, "AMMWrapperV1: Failed to transfer funds");
        } else if (_toAssetAddress == ZERO_ADDRESS || _toAssetAddress == ETH_ADDRESS) {
            IERC20 wethToken = IERC20(address(weth));
            weth.withdraw(wethToken.balanceOf(address(this)));
            makerAssetAmount = address(this).balance;
            require(makerAssetAmount >= _makerAssetAmount, "AMMWrapperV1: insufficient ETH");
            // TODO: review the amount of gas provision
            (bool success, ) = _spender.call{ gas: 30000, value: makerAssetAmount }("");
            require(success, "AMMWrapperV1: Failed to transfer funds");
        } else {
            IERC20 toAsset = IERC20(_toAssetAddress);
            makerAssetAmount = toAsset.balanceOf(address(this));
            require(makerAssetAmount >= _makerAssetAmount, "AMMWrapperV1: insufficient token");
            toAsset.safeTransfer(_spender, makerAssetAmount);
        }
        return makerAssetAmount;
    }

    function _tradeCurveTokenToToken(
        address _makerAddress,
        int128 i,
        int128 j,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount
    ) 
        internal 
    {
        ICurveFi curve = ICurveFi(_makerAddress);
        curve.exchange_underlying(i, j, _takerAssetAmount, _makerAssetAmount);
    }

    function _tradeUniswapV1EthToToken(
        address _assetAddress,
        uint256 _makerAssetAmount,
        uint256 deadline
    )
        internal
        returns (uint256 tokenBought)
    {
        IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
        address exchangeAddress = factory.getExchange(_assetAddress);
        uint256 amount = IUniswapExchange(exchangeAddress)
            .ethToTokenSwapInput
            {value: address(this).balance}(
                _makerAssetAmount,
                deadline
            );
        return amount;
    }

    function _tradeUniswapV1TokenToEth(
        address _assetAddress,
        uint256 _makerAssetAmount,
        uint256 _minEthAmount,
        uint256 deadline
    )
        internal
        returns (uint256)
    {
        IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
        address exchange = factory.getExchange(_assetAddress);
        uint256 ethAmount = IUniswapExchange(exchange)
            .tokenToEthSwapInput(
                _makerAssetAmount,
                _minEthAmount,
                deadline
            );
        return ethAmount;
    }

    function _tradeUniswapV1TokenToToken(
        address _takerAssetAddress,
        address _makerAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 deadline
    ) 
        internal 
        returns (uint256) 
    {
        IUniswapFactory factory = IUniswapFactory(UNISWAP_V1_FACTORY_ADDRESS);
        address exchange = factory.getExchange(_takerAssetAddress);
        uint256 ethAmount = IUniswapExchange(exchange)
            .tokenToEthSwapInput(
                _takerAssetAmount,
                uint256(1),
                deadline
            );
        uint256 amount = IUniswapExchange(factory.getExchange(_makerAssetAddress))
            .ethToTokenSwapInput
            {value: ethAmount}(
                _makerAssetAmount,
                deadline
            );
        return amount;
    }

    function _tradeUniswapV2TokenToToken(
        address _takerAssetAddress,
        address _makerAssetAddress,
        uint256 _takerAssetAmount,
        uint256 _makerAssetAmount,
        uint256 deadline
    ) 
        internal 
        returns (uint256) 
    {
        IUniswapRouterV2 router = IUniswapRouterV2(UNISWAP_V2_ROUTER_02_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = _takerAssetAddress;
        path[1] = _makerAssetAddress;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            _takerAssetAmount,
            _makerAssetAmount,
            path,
            address(this),
            deadline
        );
        return amounts[1];
    }
}
