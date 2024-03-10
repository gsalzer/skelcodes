// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "hardhat/console.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "../interfaces/IVault.sol";
import "../interfaces/IUniversalVault.sol";


contract Hypervisor is IVault, IUniswapV3MintCallback, IUniswapV3SwapCallback, ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 public constant MILLIBASIS = 100000;

    IUniswapV3Pool public pool;
    IERC20 public token0;
    IERC20 public token1;
    uint24 public fee;
    int24 public tickSpacing;

    int24 public baseLower;
    int24 public baseUpper;
    int24 public limitLower;
    int24 public limitUpper;

    address public owner;
    uint256 public deposit0Max;
    uint256 public deposit1Max;
    uint256 public maxTotalSupply;
    uint256 public penaltyPercent;
    mapping(address=>bool) public list;

    constructor(
        address _pool,
        address _owner,
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper
    ) ERC20("Visor ETH-USDT Uni v3", "vETH-USDTV3-1") {
        pool = IUniswapV3Pool(_pool);
        token0 = IERC20(pool.token0());
        token1 = IERC20(pool.token1());
        fee = pool.fee();
        tickSpacing = pool.tickSpacing();

        owner = _owner;

        baseLower =  _baseLower;
        baseUpper =  _baseUpper;
        limitLower =  _limitLower;
        limitUpper =  _limitUpper;
        maxTotalSupply = 0; // no cap
        deposit0Max = uint256(-1);
        deposit1Max = uint256(-1);
        penaltyPercent = 2;
    }

    function deposit(
        uint256 deposit0,
        uint256 deposit1,
        address to
    ) external override returns (uint256 shares) {
        require(deposit0 > 0 || deposit1 > 0, "deposits must be nonzero");
        require(deposit0 < deposit0Max && deposit1 < deposit1Max, "deposits must be less than maximum amounts");
        require(to != address(0) && to != address(this), "to");
        require(list[to], "must be on the list");

        // update fess for inclusion in total pool amounts
        (uint128 baseLiquidity,,) = _position(baseLower, baseUpper);
        if (baseLiquidity > 0) {
            pool.burn(baseLower, baseUpper, 0);
        }
        (uint128 limitLiquidity,,)  = _position(limitLower, limitUpper);
        if (limitLiquidity > 0) {
            pool.burn(limitLower, limitUpper, 0);
        }

        int24 currentTick = currentTick();
        uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(currentTick);
        uint256 price = uint256(sqrtPrice).mul(uint256(sqrtPrice)).mul(1e18) >> (96 * 2);

        (uint256 pool0, uint256 pool1) = getTotalAmounts();

        (shares,) = sharesCalculation(price, deposit0, deposit1, pool0, pool1);

        if (deposit0 > 0) {
          token0.safeTransferFrom(msg.sender, address(this), deposit0);
        }
        if (deposit1 > 0) {
          token1.safeTransferFrom(msg.sender, address(this), deposit1);
        }

        if (totalSupply() != 0) {
          uint256 pool0PricedInToken1 = pool0.mul(price).div(1e18);
          shares = shares.mul(totalSupply()).div(pool0PricedInToken1.add(pool1));
        }
        _mint(to, shares);
        emit Deposit(msg.sender, to, shares, deposit0, deposit1);
        // Check total supply cap not exceeded. A value of 0 means no limit.
        require(maxTotalSupply == 0 || totalSupply() <= maxTotalSupply, "maxTotalSupply");
    }

    function sharesCalculation(
        uint256 price,
        uint256 deposit0,
        uint256 deposit1,
        uint256 pool0,
        uint256 pool1
    ) public returns (uint256 shares, uint256) {
        // tokens which help balance the pool are given 100% of their token1
        // value in liquidity tokens if the deposit worsens the ratio, dock the
        // max - min amount `penaltyPercent`
        uint256 deposit0PricedInToken1 = deposit0.mul(price).div(1e18);
        uint256 pool0PricedInToken1 = pool0.mul(price).div(1e18);
        if (pool0PricedInToken1.add(deposit0PricedInToken1) >= pool1 && deposit0PricedInToken1 > deposit1) {
            shares = reduceByPercent(deposit0PricedInToken1.sub(deposit1), penaltyPercent);
            shares = shares.add(deposit1.mul(2));
        } else if (pool0PricedInToken1 <= pool1 && deposit0PricedInToken1 < deposit1) {
            shares = reduceByPercent(deposit1.sub(deposit0PricedInToken1), penaltyPercent);
            shares = shares.add(deposit0PricedInToken1.mul(2));
        } else if (pool0PricedInToken1.add(deposit0PricedInToken1) < pool1.add(deposit1) && deposit0PricedInToken1 < deposit1) {
            uint256 docked1 = pool1.add(deposit1).sub(pool0PricedInToken1.add(deposit0PricedInToken1));
            shares = reduceByPercent(docked1, penaltyPercent);
            shares = deposit1.sub(docked1).add(deposit0PricedInToken1);
        } else if (pool0PricedInToken1.add(deposit0PricedInToken1) > pool1.add(deposit1) && deposit0PricedInToken1 > deposit1) {
            uint256 docked0 = pool0PricedInToken1.add(deposit0PricedInToken1).sub(pool1.add(deposit1));
            shares = reduceByPercent(docked0, penaltyPercent);
            shares = deposit0PricedInToken1.sub(docked0).add(deposit1);
        } else {
            shares = deposit1.add(deposit0PricedInToken1);
        }

        return (shares, deposit0PricedInToken1.add(deposit1));
    }

    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(shares > 0, "shares");
        require(to != address(0), "to");

        // Withdraw liquidity from Uniswap pool
        (uint256 base0, uint256 base1) =
            _burnLiquidity(baseLower, baseUpper, _liquidityForShares(baseLower, baseUpper, shares), to, false);
        (uint256 limit0, uint256 limit1) =
            _burnLiquidity(limitLower, limitUpper, _liquidityForShares(limitLower, limitUpper, shares), to, false);

        // Push tokens proportional to unused balances
        uint256 totalSupply = totalSupply();
        uint256 unusedAmount0 = token0.balanceOf(address(this)).mul(shares).div(totalSupply);
        uint256 unusedAmount1 = token1.balanceOf(address(this)).mul(shares).div(totalSupply);
        if (unusedAmount0 > 0) token0.safeTransfer(to, unusedAmount0);
        if (unusedAmount1 > 0) token1.safeTransfer(to, unusedAmount1);

        amount0 = base0.add(limit0).add(unusedAmount0);
        amount1 = base1.add(limit1).add(unusedAmount1);

        require(from == msg.sender || IUniversalVault(from).owner() == msg.sender, "Sender must own the tokens");
        _burn(from, shares);

        emit Withdraw(from, to, shares, amount0, amount1);
    }

    function rebalance(
        int24 _baseLower,
        int24 _baseUpper,
        int24 _limitLower,
        int24 _limitUpper,
        address feeRecipient,
        int256 swapQuantity
    ) external override onlyOwner {
        require(_baseLower < _baseUpper && _baseLower % tickSpacing == 0 && _baseUpper % tickSpacing == 0,
                "base position invalid");
        require(_limitLower < _limitUpper && _limitLower % tickSpacing == 0 && _limitUpper % tickSpacing == 0,
                "limit position invalid");

        // update fees
        (uint128 baseLiquidity,,) = _position(baseLower, baseUpper);
        if (baseLiquidity > 0) {
            pool.burn(baseLower, baseUpper, 0);
        }
        (uint128 limitLiquidity,,)  = _position(limitLower, limitUpper);
        if (limitLiquidity > 0) {
            pool.burn(limitLower, limitUpper, 0);
        }

        // Withdraw all liquidity and collect all fees from Uniswap pool
        (, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
        (, uint256 feesBase0, uint256 feesBase1)  = _position(limitLower, limitUpper);

        uint256 fees0 = feesBase0.add(feesLimit0);
        uint256 fees1 = feesBase1.add(feesLimit1);
        _burnLiquidity(baseLower, baseUpper, baseLiquidity, address(this), true);
        _burnLiquidity(limitLower, limitUpper, limitLiquidity, address(this), true);

        // transfer 10% of fees for VISR buybacks
        if(fees0 > 0) token0.safeTransfer(feeRecipient, fees0.div(10));
        if(fees1 > 0) token1.safeTransfer(feeRecipient, fees1.div(10));

        emit Rebalance(
            currentTick(),
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this)),
            fees0,
            fees1,
            totalSupply()
        );

        // swap tokens if required
        if (swapQuantity != 0) {
            pool.swap(
                address(this),
                swapQuantity > 0,
                swapQuantity > 0 ? swapQuantity : -swapQuantity,
                swapQuantity > 0 ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
                abi.encode(address(this))
            );
        }

        baseLower = _baseLower;
        baseUpper = _baseUpper;
        baseLiquidity = _liquidityForAmounts(
            baseLower,
            baseUpper,
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this));

        limitLower = _limitLower;
        limitUpper = _limitUpper;
        limitLiquidity = _liquidityForAmounts(
            limitLower,
            limitUpper,
            token0.balanceOf(address(this)),
            token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this));
    }

    function _mintLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address payer
    ) internal returns (uint256 amount0, uint256 amount1) {
      if (liquidity > 0) {
            (amount0, amount1) = pool.mint(
                address(this),
                tickLower,
                tickUpper,
                liquidity,
                abi.encode(payer)
            );
        }
    }

    function _burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        address to,
        bool collectAll
    ) internal returns (uint256 amount0, uint256 amount1) {
        if (liquidity > 0) {
            // Burn liquidity
            (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);

            // Collect amount owed
            uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
            uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);
            if (collect0 > 0 || collect1 > 0) {
                (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
            }
        }
    }

    function _liquidityForShares(
        int24 tickLower,
        int24 tickUpper,
        uint256 shares
    ) internal view returns (uint128) {
        (uint128 position,,) = _position(tickLower, tickUpper);
        return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
    }

    function _position(int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1)
    {
        bytes32 positionKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
        (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);
    }

    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        address payer = abi.decode(data, (address));

        if (payer == address(this)) {
            if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
            if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
        } else {
            if (amount0 > 0) token0.safeTransferFrom(payer, msg.sender, amount0);
            if (amount1 > 0) token1.safeTransferFrom(payer, msg.sender, amount1);
        }
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pool));
        address payer = abi.decode(data, (address));

        if (amount0Delta > 0) {
            if (payer == address(this)) {
                token0.transfer(msg.sender, uint256(amount0Delta));
            } else {
                token0.safeTransferFrom(payer, msg.sender, uint256(amount0Delta));
            }
        } else if (amount1Delta > 0) {
            if (payer == address(this)) {
                token1.transfer(msg.sender, uint256(amount1Delta));
            } else {
                token1.safeTransferFrom(payer, msg.sender, uint256(amount1Delta));
            }
        }
    }

    function getTotalAmounts() public view override returns (uint256 total0, uint256 total1) {
        (, uint256 base0, uint256 base1) = getBasePosition();
        (, uint256 limit0, uint256 limit1) = getLimitPosition();
        total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
        total1 = token1.balanceOf(address(this)).add(base1).add(limit1);
    }

    function getBasePosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(baseLower, baseUpper);
        (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    function getLimitPosition()
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(limitLower, limitUpper);
        (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
        amount0 = amount0.add(uint256(tokensOwed0));
        amount1 = amount1.add(uint256(tokensOwed1));
        liquidity = positionLiquidity;
    }

    function _amountsForLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) internal view returns (uint256, uint256) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                liquidity
            );
    }

    function _liquidityForAmounts(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) internal view returns (uint128) {
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(tickLower),
                TickMath.getSqrtRatioAtTick(tickUpper),
                amount0,
                amount1
            );
    }

    function currentTick() public view returns (int24 currentTick) {
        (, currentTick, , , , , ) = pool.slot0();
    }

    function _uint128Safe(uint256 x) internal pure returns (uint128) {
        assert(x <= type(uint128).max);
        return uint128(x);
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setDepositMax(uint256 _deposit0Max, uint256 _deposit1Max) external onlyOwner {
        deposit0Max = _deposit0Max;
        deposit1Max = _deposit1Max;
    }

    function setPenaltyPercent(uint256 _penaltyPercent) external onlyOwner {
        penaltyPercent = _penaltyPercent;
    }

    function reduceByPercent(uint256 quantity, uint256 percent) internal view returns (uint256) {
          return quantity.mul(MILLIBASIS.mul(100 - percent)).div(MILLIBASIS.mul(100));
    }

    function emergencyWithdraw(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    function emergencyBurn(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) external onlyOwner {
        pool.burn(tickLower, tickUpper, liquidity);
        pool.collect(msg.sender, tickLower, tickUpper, type(uint128).max, type(uint128).max);
    }

    function appendList(address[] memory listed) external onlyOwner {
        for (uint8 i; i < listed.length; i++) {
          list[listed[i]] = true; 
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
      owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}

