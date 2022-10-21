pragma solidity 0.5.17;


interface IDextokenPool {
    event TokenDeposit(
        address indexed token, 
        address indexed account, 
        uint amount,
        uint spotPrice
    );

    event TokenWithdraw(
        address indexed token, 
        address indexed account, 
        uint amount,
        uint spotPrice
    );

    event SwapExactETHForTokens(
        address indexed poolOut, 
        uint amountOut, 
        uint amountIn,
        uint spotPrice,
        address indexed account
    );

    event SwapExactTokensForETH(
        address indexed poolOut, 
        uint amountOut, 
        uint amountIn, 
        uint spotPrice,
        address indexed account
    );

    /// Speculative AMM
    function initialize(address _token0, address _token1, uint _Ct, uint _Pt) external;
    function mean() external view returns (uint);
    function getLastUpdateTime() external view returns (uint);
    function getCirculatingSupply() external view returns (uint);
    function getUserbase() external view returns (uint);
    function getPrice() external view returns (uint);
    function getSpotPrice(uint _Ct, uint _Nt) external pure returns (uint);
	function getToken() external view returns (address);

    /// Pool Management
    function getPoolBalance() external view returns (uint);    
    function getTotalLiquidity() external view returns (uint);
    function liquidityOf(address account) external view returns (uint);
    function liquiditySharesOf(address account) external view returns (uint);
    function liquidityTokenToAmount(uint token) external view returns (uint);
    function liquidityFromAmount(uint amount) external view returns (uint);
    function deposit(uint amount) external;
    function withdraw(uint tokens) external;

    /// Trading
    function swapExactETHForTokens(
        uint amountIn,
        uint minAmountOut,
        uint maxPrice,
        uint deadline
    ) external returns (uint);

    function swapExactTokensForETH(
        uint amountIn,
        uint minAmountOut,
        uint minPrice,
        uint deadline
    ) external returns (uint);
}
