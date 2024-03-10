// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./OracleRef.sol";
import "./IUniRef.sol";

/// @title A Reference to Uniswap
/// @author Ring Protocol
/// @notice defines some modifiers and utilities around interacting with Uniswap
/// @dev the uniswap v3 pool should be RUSD and another asset
abstract contract UniRef is IUniRef, OracleRef {
    using Decimal for Decimal.D256;
    using SafeMathCopy for uint256;
    using SafeMathCopy for uint160;

    uint256 private constant FIXED_POINT_GRANULARITY = 2**96;

    /// @notice the Uniswap V3 position manager
    INonfungiblePositionManager public override nft;

    /// @notice the Uniswap router contract
    ISwapRouter public override router;

    /// @notice the referenced Uniswap V3 pool contract
    IUniswapV3Pool public override pool;
    
    /// @notice the referenced Uniswap V3 pool position id
    uint256 public override tokenId;

    /// @notice UniRef constructor
    /// @param _core Ring Core to reference
    /// @param _pool Uniswap V3 pool to reference
    /// @param _nft Uniswap V3 position manager to reference
    /// @param _router Uniswap Router to reference
    /// @param _oracle oracle to reference
    constructor(
        address _core,
        address _pool,
        address _nft,
        address _router,
        address _oracle
    ) OracleRef(_core, _oracle) {
        _setupPool(_pool);

        nft = INonfungiblePositionManager(_nft);
        router = ISwapRouter(_router);

        _approveTokenToRouter(address(rusd()));
        _approveTokenToRouter(token());
        _approveTokenToNFT(address(rusd()));
        _approveTokenToNFT(token());
    }

    /// @notice set the new pool contract
    /// @param _pool the new pool
    /// @dev also approves the router for the new pool token and underlying token
    function setPool(address _pool) external override onlyGovernor {
        _setupPool(_pool);

        _approveTokenToRouter(token());
        _approveTokenToNFT(token());
    }

    /// @notice the address of the non-rusd underlying token
    function token() public view override returns (address) {
        address token0 = pool.token0();
        if (address(rusd()) == token0) {
            return pool.token1();
        }
        return token0;
    }

    /// @notice amount of pool liquidity owned by this contract
    /// @return amount of liquidity
    function liquidityOwned() public view override returns (uint128) {
        (, , , , , , , uint128 liquidity, , , , ) = nft.positions(tokenId);
        return liquidity;
    }

    /// @notice returns true if price is below the peg
    /// @dev counterintuitively checks if peg < price because price is reported as RUSD per X
    function _isBelowPeg(Decimal.D256 memory peg) internal view returns (bool) {
        Decimal.D256 memory price = _getUniswapPrice();
        return peg.lessThan(price);
    }

    /// @notice approves a token for the router
    function _approveTokenToRouter(address _token) internal {
        uint256 maxTokens = uint256(-1);
        TransferHelper.safeApprove(_token, address(router), maxTokens);
    }

    /// @notice approves a token for the position manager
    function _approveTokenToNFT(address _token) internal {
        uint256 maxTokens = uint256(-1);
        TransferHelper.safeApprove(_token, address(nft), maxTokens);
    }

    function _setupPool(address _pool) internal {
        pool = IUniswapV3Pool(_pool);
        emit PoolUpdate(_pool);
    }

    /// @notice get uniswap price
    /// @return price reported as Rusd per X
    function _getUniswapPrice()
        internal
        view
        returns (Decimal.D256 memory)
    {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        if (token() < address(rusd())) {
            return Decimal.ratio(sqrtPriceX96, FIXED_POINT_GRANULARITY).pow(2);
        } else {
            return Decimal.ratio(FIXED_POINT_GRANULARITY, sqrtPriceX96).pow(2);
        }
    }

    /// @notice return current percent distance from peg
    /// @dev will return Decimal.zero() if above peg
    function _getDistanceToPeg()
        internal
        view
        returns (Decimal.D256 memory distance)
    {
        Decimal.D256 memory price = _getUniswapPrice();
        return _deviationBelowPeg(price, peg());
    }

    /// @notice get deviation from peg as a percent given price
    /// @dev will return Decimal.zero() if above peg
    function _deviationBelowPeg(
        Decimal.D256 memory price,
        Decimal.D256 memory peg
    ) internal pure returns (Decimal.D256 memory) {
        // If price <= peg, then RUSD is more expensive and above peg
        // In this case we can just return zero for deviation
        if (price.lessThanOrEqualTo(peg)) {
            return Decimal.zero();
        }
        Decimal.D256 memory delta = price.sub(peg, "Impossible underflow");
        return delta.div(peg);
    }
}

