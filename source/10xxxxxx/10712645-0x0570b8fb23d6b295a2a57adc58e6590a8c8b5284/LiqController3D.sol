contract UniswapV2Router02 {
    function addLiquidityETH (
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint, uint, uint);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    address public WETH;
}

interface IUniswapV2ERC20 {
    function balanceOf(address owner) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

contract LiqController3D {
    uint constant rate = 1;
    uint lastClaim;
    address routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address tokenAddr;
    address owner;

    UniswapV2Router02 router;
    IUniswapV2ERC20 liq;

    constructor(address _tokenAddr, address _poolAddr) public {
        owner =  tx.origin;
        lastClaim = now;
        tokenAddr = _tokenAddr;

        router = UniswapV2Router02(routerAddr);
        liq = IUniswapV2ERC20(_poolAddr);
    }

    function removeLiq(uint _withdrawType) external {
        require(msg.sender==owner);
        require(now - lastClaim > 1 days);
        require(_withdrawType==1 || _withdrawType==2, 'Invalid Withdraw Type');
        
        uint bal = liq.balanceOf(address(this));
        uint liqAmount;

        if (bal < 100){ liqAmount = bal; }  // Collect remaining dust
        else { liqAmount = (bal * rate) / 100; }

        if (_withdrawType == 1) {
            router.removeLiquidityETH(tokenAddr, liqAmount, 1, 1, owner, now);
        }

        else if (_withdrawType == 2) { 
            liq.transfer(owner, liqAmount);   
        }

        lastClaim = now;
    }

    function approveLiqTokens() external {
        liq.approve(routerAddr, uint(-1));
    }
}
