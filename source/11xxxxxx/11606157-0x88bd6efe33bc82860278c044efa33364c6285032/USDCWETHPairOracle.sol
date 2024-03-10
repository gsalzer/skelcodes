// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import './IUniswapV2Router02.sol';


// Fixed window oracle that recomputes the average price for the entire period once every period
// Note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract USDCWETHPairOracle {
    
    IUniswapV2Router02  public  router;
    address public router_address;
    address public USDC;
    // address public router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // address public USDC = 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48;

    constructor (address _router, address _usdc) public {
       router_address = _router;
       USDC = _usdc;
    }



    // Note this will always return 0 before update has been called successfully for the first time.
    // function consult(address token, uint amountIn) external view returns (uint amountOut) {
    //     uint256[] memory amounts = new 
    //     (, amountOut) = router(router_address).getAmountsOut(amountIn,[USDC,token]);
    // }
}

