
pragma solidity ^0.6.12;

import './IUniswapV2Router02.sol';
import './SafeERC20.sol';
import './IERC20.sol';
import './Ownable.sol';
import './Whirlpool.sol';

contract TheEvent is Ownable {
    using SafeERC20 for IERC20;
    
    Whirlpool public whirlpool;
    IERC20 public surf;
    IERC20 public surfPool;
    IERC20 public weth;
    IUniswapV2Router02 constant internal uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    uint256 internal minPercent = 100; // 10%
    uint256 internal maxPercent = 200; // 20%

    constructor(Whirlpool _whirlpool) public {
        whirlpool = _whirlpool;
        surf = IERC20(whirlpool.surf());
        surfPool = whirlpool.surfPool();
        weth = IERC20(uniswapRouter.WETH());
    }

    function setMinPercent(uint256 _value) external onlyOwner {
        require(_value < maxPercent);
        minPercent = _value;
    }

    function setMaxPercent(uint256 _value) external onlyOwner {
        require(_value > minPercent && _value <= 1000);
        maxPercent = _value;
    }

    function getPrice() public view onlyOwner returns (uint256 surfPrice) {
        surfPrice = 10**18 * weth.balanceOf(address(surfPool)) / surf.balanceOf(address(surfPool));
    }

    function processTheEvent(uint256 _price, bool _processRemainder) external onlyOwner {
        // Make sure the current price of SURF is within 1% of the _price argument
        if (_price > 0) {
            uint256 _surfPrice = getPrice();

            uint256 _onePercent = _price / 100;
            uint256 _priceMin = _price - _onePercent;
            uint256 _priceMax = _price + _onePercent;
            require(_surfPrice >= _priceMin && _surfPrice <= _priceMax, "price moved too much");
        }

        // Determine the % of LP tokens to remove liquidity for
        uint256 _amount;
        if (_processRemainder) {
            _amount = surfPool.balanceOf(address(this));
        } else {
            uint256 _percent = minPercent + (uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), gasleft()))) % (maxPercent - minPercent));
            _amount = surfPool.balanceOf(address(this)) * _percent / 1000;
        }

        require(_amount > 0);

        // Remove the liquidity from Uniswap, using the Whirlpool as the recipient
        surfPool.safeApprove(address(uniswapRouter), 0);
        surfPool.safeApprove(address(uniswapRouter), _amount);
        uniswapRouter.removeLiquidityETHSupportingFeeOnTransferTokens(address(surf), _amount, 0, 0, address(whirlpool), block.timestamp + 5 minutes);
        
        // The ETH and SURF have been transferred to the Whirlpool, so call .addEthReward() to have the Whirlpool buy SURF with all of the ETH
        whirlpool.addEthReward();
    }
}
