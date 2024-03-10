pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../../interface/curve/Gauge.sol";
import "../../interface/curve/ICurveEURSDeposit.sol";
import "../../interface/uniswap/IUniswapV2Router02.sol";
import "../../interface/IStrategy.sol";
import "../../interface/IVault.sol";

import "../../StrategyBase.sol";

/**
* This strategy is for the mixToken vault, i.e., the underlying token is mixToken. It is not to accept
* stable coins. It will farm the CRV crop. For liquidation, it swaps CRV into EURS and uses EURS
* to produce mixToken.
*/
contract CRVStrategyEURSV2 is StrategyBase {

  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  event Liquidating(uint256 amount);
  event ProfitsNotCollected();

  // crvEURS
  address public pool;
  address public mintr;
  address public crv;
  address public snx;

  address public weth;
  address public usdc;
  address public eurs;
  address public curveDepositEURS;

  address public uni;

  uint256 maxUint = uint256(~0);

  address[] public rewardTokens;
  // a flag for disabling selling for simplified emergency exit
  mapping (address => bool) public sell;
  bool public globalSell = true;
  // minimum amount to be liquidation
  mapping (address => uint256) public sellFloor;
  mapping (address => address[]) public uniswapLiquidationPath;

  constructor(
    address _storage,
    address _vault,
    address _underlying,
    address _gauge,
    address _mintr,
    address _crv,
    address _snx,
    address _weth,
    address _usdc,
    address _eurs,
    address _curveDepositEURS,
    address _uniswap
  )
  StrategyBase(_storage, _underlying, _vault, _weth, _uniswap) public {
    require(IVault(_vault).underlying() == _underlying, "vault does not support eursCRV");
    pool = _gauge;
    mintr = _mintr;
    crv = _crv;
    snx = _snx;
    weth = _weth;
    usdc = _usdc;
    eurs = _eurs;
    curveDepositEURS = _curveDepositEURS;
    uni = _uniswap;

    globalSell = true;

    unsalvagableTokens[crv] = true;
    sell[crv] = true;
    sellFloor[crv] = 1e16;
    uniswapLiquidationPath[crv] = [crv, weth];

    unsalvagableTokens[snx] = true;
    sell[snx] = true;
    sellFloor[snx] = 1e16;
    uniswapLiquidationPath[snx] = [snx, weth];

    uniswapLiquidationPath[weth] = [weth, usdc, eurs];
    rewardTokens.push(crv);
    rewardTokens.push(snx);
  }

  function depositArbCheck() public view returns(bool) {
    return true;
  }

  function salvage(address recipient, address token, uint256 amount) public onlyGovernance {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvageable");
    IERC20(token).safeTransfer(recipient, amount);
  }

  /**
  * Withdraws underlying from the investment pool that mints crops.
  */
  function withdrawUnderlyingFromPool(uint256 amount) internal {
    Gauge(pool).withdraw(
      Math.min(Gauge(pool).balanceOf(address(this)), amount)
    );
  }

  /**
  * Withdraws the underlying tokens to the pool in the specified amount.
  */
  function withdrawToVault(uint256 amountUnderlying) external restricted {
    withdrawUnderlyingFromPool(amountUnderlying);
    require(IERC20(underlying).balanceOf(address(this)) >= amountUnderlying, "insufficient balance for the withdrawal");
    IERC20(underlying).safeTransfer(vault, amountUnderlying);
  }

  /**
  * Withdraws all the underlying tokens to the pool.
  */
  function withdrawAllToVault() external restricted {
    claimAndLiquidateReward();
    withdrawUnderlyingFromPool(maxUint);
    uint256 balance = IERC20(underlying).balanceOf(address(this));
    IERC20(underlying).safeTransfer(vault, balance);
  }

  /**
  * Invests all the underlying into the pool that mints crops (CRV)
  */
  function investAllUnderlying() public restricted {
    uint256 underlyingBalance = IERC20(underlying).balanceOf(address(this));
    if (underlyingBalance > 0) {
      IERC20(underlying).safeApprove(pool, 0);
      IERC20(underlying).safeApprove(pool, underlyingBalance);
      Gauge(pool).deposit(underlyingBalance);
    }
  }

  /**
  * Claims the CRV crop, converts it to EURS on Uniswap, and then uses EURS to mint underlying using the
  * Curve protocol.
  */
  function claimAndLiquidateReward() internal {
    if (!globalSell) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(address(0x0));
      return;
    }
    Mintr(mintr).mint(pool);

    // rewardTokens, ellFloor, sell, uniswapLiquidationPath
    // All sell to WETH
    for(uint256 i = 0; i < rewardTokens.length; i++){
      address rewardToken = rewardTokens[i];
      uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
      if (rewardBalance < sellFloor[rewardToken] || !sell[rewardToken]) {
        // Profits can be disabled for possible simplified and rapid exit
        emit ProfitsNotCollected(rewardToken);
      } else {      
        emit Liquidating(rewardToken, rewardBalance);
        IERC20(rewardToken).safeApprove(uni, 0);
        IERC20(rewardToken).safeApprove(uni, rewardBalance);
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        IUniswapV2Router02(uni).swapExactTokensForTokens(
          rewardBalance, 1, uniswapLiquidationPath[rewardToken], address(this), block.timestamp
        );
      }      
    }

    uint256 wethRewardBalance = IERC20(weth).balanceOf(address(this));

    notifyProfitInRewardToken(wethRewardBalance);

    wethRewardBalance = IERC20(weth).balanceOf(address(this));

    if(IERC20(weth).balanceOf(address(this)) > 0) {
        IERC20(weth).safeApprove(uni, 0);
        IERC20(weth).safeApprove(uni, wethRewardBalance);
        // we can accept 1 as the minimum because this will be called only by a trusted worker
        // swap to eur
        IUniswapV2Router02(uni).swapExactTokensForTokens(
          wethRewardBalance, 1, uniswapLiquidationPath[weth], address(this), block.timestamp
        );
        eursCRVFromEurs();  
    }
  }

  /**
  * Claims and liquidates CRV into underlying, and then invests all underlying.
  */
  function doHardWork() public restricted {
    claimAndLiquidateReward();
    investAllUnderlying();
  }

  /**
  * Investing all underlying.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    return Gauge(pool).balanceOf(address(this)).add(
      IERC20(underlying).balanceOf(address(this))
    );
  }

  /**
  * Converts all EURS to underlying using the CRV protocol.
  */
  function eursCRVFromEurs() internal {
    uint256 eursBalance = IERC20(eurs).balanceOf(address(this));
    if (eursBalance > 0) {
      IERC20(eurs).safeApprove(curveDepositEURS, 0);
      IERC20(eurs).safeApprove(curveDepositEURS, eursBalance);

      // we can accept 0 as minimum, this will be called only by trusted roles
      uint256 minimum = 0;
      ICurveEURSDeposit(curveDepositEURS).add_liquidity([eursBalance, 0], minimum);
      // now we have eursCRV
    }
  }

  /**
  * Can completely disable claiming reward rewards and selling. Good for emergency withdraw in the
  * simplest possible way.
  */
  function setSell(address rt, bool s) public onlyGovernance {
    sell[rt] = s;
  }

  function setGlobalSell(bool s) public onlyGovernance {
    globalSell = s;
  }

  /**
  * Sets the minimum amount of CRV needed to trigger a sale.
  */
  function setSellFloor(address rt, uint256 floor) public onlyGovernance {
    sellFloor[rt] = floor;
  }

  function setRewardTokens(address[] memory rts) public onlyGovernance {
    rewardTokens = rts;
  }

  function setLiquidationPath(address rewardToken, address[] memory liquidationPath) public onlyGovernance {
    uniswapLiquidationPath[rewardToken] = liquidationPath;
  }

}

