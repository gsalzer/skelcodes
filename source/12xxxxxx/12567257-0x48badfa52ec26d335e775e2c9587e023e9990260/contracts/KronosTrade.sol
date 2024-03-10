pragma solidity >=0.7.6;
pragma abicoder v2;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
interface PoolInterface {
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);
    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);
}

interface IWeth{
    function deposit() external payable;
    function withdraw(uint wad) external;
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns(uint);
}

contract Ownable {
    address payable public _OWNER_;
    address payable public _NEW_OWNER_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // ============ Modifiers ============

    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }

    // ============ Functions ============

    constructor() {
        _OWNER_ = msg.sender;
        emit OwnershipTransferred(address(0), _OWNER_);
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferPrepared(_OWNER_, newOwner);
        _NEW_OWNER_ = newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == _NEW_OWNER_, "INVALID_CLAIM");
        emit OwnershipTransferred(_OWNER_, _NEW_OWNER_);
        _OWNER_ = _NEW_OWNER_;
        _NEW_OWNER_ = address(0);
    }
}

contract Tradable is Ownable{
    mapping(address=>bool) _ALLOWEDTRADERS_;
    
    modifier onlyTraders(){
        require(_ALLOWEDTRADERS_[msg.sender],"NOT_TRADER");
        _;
    }
    
    function approveTraderAddress (address trader) external onlyOwner {
        _ALLOWEDTRADERS_[trader] = true;
    }
    
    function removeTraderAddress (address trader) external onlyOwner {
        require(_ALLOWEDTRADERS_[trader],"TRADER_NOT_IN_LIST");
        _ALLOWEDTRADERS_[trader] = false;
    }
    
}

contract KronosTrade is Ownable,Tradable {
  address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address internal constant NFT_ADDRESS = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
  IUniswapV2Router02 public uniswapRouter;
  INonfungiblePositionManager public NftPositionManager;
    
 constructor() {
    uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    NftPositionManager = INonfungiblePositionManager(NFT_ADDRESS);
  }
// ============ Util Functions ============
function setUniSwapRouter(address uniswap_router_addr)external onlyOwner
{
  uniswapRouter = IUniswapV2Router02(uniswap_router_addr);
}

function balanceOfToken(address token_address) external view returns(uint){
    IERC20 token = IERC20(token_address);
    return token.balanceOf(address(this));
}

function balanceOfThis() external view returns(uint) {
    return address(this).balance;
}

// ============ Withdraw Functions ============
// Only owner
  
function withdrawAllFunds() external onlyOwner {
    msg.sender.transfer(address(this).balance);
}

function withdrawFunds(uint withdrawAmount) external onlyOwner {
    require(withdrawAmount <= address(this).balance);
    msg.sender.transfer(withdrawAmount);
}

function withdrawToken(uint withdrawAmount, address token_address) external onlyOwner {
    IERC20 token = IERC20(token_address);
    uint token_balance = token.balanceOf(address(this));
    require(withdrawAmount <= token_balance);
    token.transfer(msg.sender, withdrawAmount);
}

function withdrawAllToken(address token_address) external onlyOwner {
    IERC20 token = IERC20(token_address);
    token.transfer(msg.sender, token.balanceOf(address(this)));
}

// Only Traders
// An trigger For traders withdraw funds and only send to Onwer
function withdrawAllFundsToOwner() external onlyTraders {
    _OWNER_.transfer(address(this).balance);
}

function withdrawTokensToOnwer(uint withdrawAmount, address token_address) external onlyTraders {
    IERC20 token = IERC20(token_address);
    uint token_balance = token.balanceOf(address(this));
    require(withdrawAmount <= token_balance);
    token.transfer(_OWNER_, withdrawAmount);
}

function withdrawAllTokenToOwner(address token_address) external onlyTraders {
    IERC20 token = IERC20(token_address);
    token.transfer(_OWNER_, token.balanceOf(address(this)));
}

// ============ Trading Functions ============

function swapETHtoWETH(uint amounts) external onlyTraders {
    IWeth weth = IWeth(uniswapRouter.WETH());
    weth.deposit{value:amounts}();
}

function swapWETHtoETH(uint amounts) external onlyTraders {
    IWeth weth = IWeth(uniswapRouter.WETH());
    weth.withdraw(amounts);
}

function provideLiquidity(address token0,
    address token1,
    uint24 fee,
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min) external onlyTraders {
        
    uint256 deadline = block.timestamp + 15;
    _tokenApprove(amount0Desired,NFT_ADDRESS,token0);
    _tokenApprove(amount1Desired,NFT_ADDRESS,token1);
    INonfungiblePositionManager.MintParams memory mintparam = INonfungiblePositionManager.MintParams(token0,token1,fee,tickLower,tickUpper,amount0Desired,amount1Desired,amount0Min,amount1Min,address(this),deadline);
    NftPositionManager.mint(mintparam);
    
}

function removeLiquidity(uint256 tokenId, 
    uint128 liquidity, 
    uint128 amount0Max, 
    uint128 amount1Max,
    uint256 amount0Min,
    uint256 amount1Min) external onlyTraders {
        
    uint256 deadline = block.timestamp + 15;
    INonfungiblePositionManager.DecreaseLiquidityParams memory DecLiqParams = INonfungiblePositionManager.DecreaseLiquidityParams(tokenId, liquidity, amount0Min, amount1Min,deadline);
    INonfungiblePositionManager.CollectParams memory CollLiqParams = INonfungiblePositionManager.CollectParams(tokenId, address(this), amount0Max, amount1Max);
    NftPositionManager.decreaseLiquidity(DecLiqParams);
    NftPositionManager.collect(CollLiqParams);
}

function insertOrder(uint amount, address[] memory paths) external onlyTraders returns(uint){
    uint deadline = block.timestamp + 15;
    uint amounts = amount;
    
    // Token to Token
    for(uint i = 0;i<paths.length-1;i++)
    {
        _tokenApprove(amounts,UNISWAP_ROUTER_ADDRESS,paths[i]);
        amounts = uniswapRouter.swapExactTokensForTokens(amounts, 1, getPathBetween(paths[i],paths[i+1]), address(this), deadline)[1];
        
    }

  return amounts;
}
  
function insertOrder(uint amount, address[] memory paths, uint expect_out) external onlyTraders returns(uint){
    uint deadline = block.timestamp + 15;
    uint amounts = amount;
    uint amounts_check = amount;
    for(uint i = 0;i<paths.length-1;i++)
    {
        amounts_check = uniswapRouter.getAmountsOut(amounts_check, getPathBetween(paths[i],paths[i+1]))[1];
    }
    require(amounts_check > expect_out,"INSERT CANCELLED");
    
    // Token to Token
    for(uint i = 0;i<paths.length-1;i++)
    {
        _tokenApprove(amounts,UNISWAP_ROUTER_ADDRESS,paths[i]);
        amounts = uniswapRouter.swapExactTokensForTokens(amounts, 1, getPathBetween(paths[i],paths[i+1]), address(this), deadline)[1];
        
    }
    
  return amounts;
}
  
  function getPathBetween(address p1, address p2) private returns (address[] memory)
  {
      address[] memory path = new address[](2);
      path[0] = p1;
      path[1] = p2;
      return path;
  }
  
  function _tokenApprove(uint entry,address swapAddr, address tokenAddr) private{
      IERC20 token = IERC20(tokenAddr);
      if(token.allowance(address(this), swapAddr) < entry){
        token.approve(swapAddr, entry);
      }
  }

  // important to receive ETH
  receive() payable external {}
}

