pragma solidity 0.5.17;


interface IDextokenExchange {
    event SwapExactAmountOut(
        address indexed poolIn, 
        uint amountSwapIn, 
        address indexed poolOut, 
        uint exactAmountOut,
        address indexed to
    );

    event SwapExactAmountIn(
        address indexed poolIn, 
        uint amountSwapIn, 
        address indexed poolOut, 
        uint exactAmountOut,
        address indexed to
    );
    
	function swapMaxAmountOut(
        address poolIn,
        address poolOut, 
        uint maxAmountOut,
        uint deadline
    ) external;

    function swapExactAmountIn(
        address poolIn,
        address poolOut, 
        uint exactAmountIn,
        uint deadline
    ) external;  
}
