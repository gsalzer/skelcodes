// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma abicoder v2;

import "../../internal/markets/Market.sol";
import "../../internal/nTokenHandler.sol";
import "../../internal/portfolio/PortfolioHandler.sol";
import "../../internal/portfolio/TransferAssets.sol";
import "../../internal/balances/BalanceHandler.sol";
import "../../external/FreeCollateralExternal.sol";
import "../../external/SettleAssetsExternal.sol";
import "../../math/SafeInt256.sol";
import "./ActionGuards.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract nTokenRedeemAction is ActionGuards {
    using SafeInt256 for int256;
    using SafeMath for uint256;
    using BalanceHandler for BalanceState;
    using Market for MarketParameters;
    using CashGroup for CashGroupParameters;
    using PortfolioHandler for PortfolioState;
    using AccountContextHandler for AccountContext;
    using nTokenHandler for nTokenPortfolio;

    event nTokenSupplyChange(address indexed account, uint16 indexed currencyId, int256 tokenSupplyChange);

    /// @notice When redeeming nTokens via the batch they must all be sold to cash and this
    /// method will return the amount of asset cash sold. This method can only be invoked via delegatecall.
    /// @param currencyId the currency associated the nToken
    /// @param tokensToRedeem the amount of nTokens to convert to cash
    /// @dev auth:only internal
    /// @return amount of asset cash to return to the account, denominated in internal token decimals
    function nTokenRedeemViaBatch(uint16 currencyId, int256 tokensToRedeem)
        external
        returns (int256)
    {
        // Only self call allowed
        require(msg.sender == address(this), "Unauthorized caller");
        uint256 blockTime = block.timestamp;
        // prettier-ignore
        (
            int256 totalAssetCash,
            bool hasResidual,
            /* PortfolioAssets[] memory newfCashAssets */
        ) = _redeem(currencyId, tokensToRedeem, true, blockTime);

        require(!hasResidual, "Cannot redeem via batch, residual");
        return totalAssetCash;
    }

    /// @notice Allows accounts to redeem nTokens into constituent assets and then absorb the assets
    /// into their portfolio. Due to the complexity here, it is not allowed to be called during a batch trading
    /// operation and must be done separately.
    /// @param redeemer the address that holds the nTokens to redeem
    /// @param currencyId the currency associated the nToken
    /// @param tokensToRedeem_ the amount of nTokens to convert to cash
    /// @param sellTokenAssets attempt to sell residual fCash and convert to cash, if unsuccessful then
    /// residual fCash assets will be placed into the portfolio
    /// @dev auth:msg.sender auth:ERC1155
    /// @return total amount of asset cash redeemed
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets
    ) external nonReentrant returns (int256) {
        // ERC1155 can call this method during a post transfer event
        require(msg.sender == redeemer || msg.sender == address(this), "Unauthorized caller");

        uint256 blockTime = block.timestamp;
        int256 tokensToRedeem = int256(tokensToRedeem_);

        AccountContext memory context = AccountContextHandler.getAccountContext(redeemer);
        if (context.mustSettleAssets()) {
            context = SettleAssetsExternal.settleAccount(redeemer, context);
        }

        BalanceState memory balance;
        balance.loadBalanceState(redeemer, currencyId, context);

        require(balance.storedNTokenBalance >= tokensToRedeem, "Insufficient tokens");
        balance.netNTokenSupplyChange = tokensToRedeem.neg();

        (int256 totalAssetCash, bool hasResidual, PortfolioAsset[] memory assets) =
            _redeem(currencyId, tokensToRedeem, sellTokenAssets, blockTime);

        // Set balances before transferring assets
        balance.netCashChange = totalAssetCash;
        balance.finalize(redeemer, context, false);

        if (hasResidual) {
            // This method will store assets and update the account context in memory
            context = TransferAssets.placeAssetsInAccount(redeemer, context, assets);
        }

        context.setAccountContext(redeemer);
        if (context.hasDebt != 0x00) {
            FreeCollateralExternal.checkFreeCollateralAndRevert(redeemer);
        }

        emit nTokenSupplyChange(redeemer, currencyId, balance.netNTokenSupplyChange);
        return totalAssetCash;
    }

    /// @notice Redeems nTokens for asset cash and fCash
    /// @return assetCash: positive amount of asset cash to the account
    /// @return hasResidual: true if there are fCash residuals left
    /// @return assets: an array of fCash asset residuals to place into the account
    function _redeem(
        uint16 currencyId,
        int256 tokensToRedeem,
        bool sellTokenAssets,
        uint256 blockTime
    )
        private
        returns (
            int256,
            bool,
            PortfolioAsset[] memory
        )
    {
        require(tokensToRedeem > 0);
        nTokenPortfolio memory nToken;
        nToken.loadNTokenPortfolioStateful(currencyId);
        // nTokens cannot be redeemed during the period of time where they require settlement.
        require(nToken.getNextSettleTime() > blockTime, "PT: requires settlement");

        // Get the assetCash and fCash assets as a result of redeeming tokens
        (PortfolioAsset[] memory newfCashAssets, int256 totalAssetCash) =
            _reduceTokenAssets(nToken, tokensToRedeem, blockTime);

        // hasResidual is set to true if fCash assets need to be put back into the redeemer's portfolio
        bool hasResidual = true;
        if (sellTokenAssets) {
            int256 assetCash;
            // NOTE: newfCashAssets is modified in place during this method
            (assetCash, hasResidual) = _sellfCashAssets(
                nToken.cashGroup,
                newfCashAssets,
                blockTime
            );

            totalAssetCash = totalAssetCash.add(assetCash);
        }

        return (totalAssetCash, hasResidual, newfCashAssets);
    }

    /// @notice Removes nToken assets
    /// @return newifCashAssets: an array of fCash assets the redeemer will take
    /// @return assetCash: amount of cash the redeemer will take
    function _reduceTokenAssets(
        nTokenPortfolio memory nToken,
        int256 tokensToRedeem,
        uint256 blockTime
    ) private returns (PortfolioAsset[] memory, int256) {
        // Get share of ifCash assets to remove
        PortfolioAsset[] memory newifCashAssets =
            BitmapAssetsHandler.reduceifCashAssetsProportional(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.lastInitializedTime,
                tokensToRedeem,
                nToken.totalSupply
            );

        // Get asset cash share for the nToken, if it exists. It is required in balance handler that the
        // nToken can never have a negative cash asset cash balance so what we get here is always positive.
        int256 assetCashShare = nToken.cashBalance.mul(tokensToRedeem).div(nToken.totalSupply);
        if (assetCashShare > 0) {
            nToken.cashBalance = nToken.cashBalance.subNoNeg(assetCashShare);
            BalanceHandler.setBalanceStorageForNToken(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.cashBalance
            );
        }

        // Get share of liquidity tokens to remove, newifCashAssets is modified in memory
        // during this method.
        assetCashShare = assetCashShare.add(
            _removeLiquidityTokens(
                nToken,
                newifCashAssets,
                tokensToRedeem,
                nToken.totalSupply,
                blockTime
            )
        );

        {
            // prettier-ignore
            (
                /* hasDebt */,
                /* currencies */,
                uint8 newStorageLength,
                /* nextSettleTime */
            ) = nToken.portfolioState.storeAssets(nToken.tokenAddress);

            // This can happen if a liquidity token is redeemed down to zero. It's possible that due to dust amounts
            // one token is reduced down to a zero balance while the others still have some amount remaining. In this case
            // the mint nToken will fail in `addLiquidityToMarket`, an account must accept redeeming part of their
            // nTokens and leaving some dust amount behind.
            require(
                nToken.portfolioState.storedAssets.length == uint256(newStorageLength),
                "Cannot redeem to zero"
            );
        }

        // NOTE: Token supply change will happen when we finalize balances and after minting of incentives
        return (newifCashAssets, assetCashShare);
    }

    /// @notice Removes nToken liquidity tokens and updates the netfCash figures.
    function _removeLiquidityTokens(
        nTokenPortfolio memory nToken,
        PortfolioAsset[] memory newifCashAssets,
        int256 tokensToRedeem,
        int256 totalSupply,
        uint256 blockTime
    ) private returns (int256 totalAssetCash) {
        MarketParameters memory market;

        for (uint256 i = 0; i < nToken.portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = nToken.portfolioState.storedAssets[i];
            int256 tokensToRemove = asset.notional.mul(tokensToRedeem).div(totalSupply);
            asset.notional = asset.notional.sub(tokensToRemove);
            // Cannot redeem liquidity tokens down to zero or this will cause many issues with
            // market initialization.
            require(asset.notional > 0, "Cannot redeem to zero");
            require(asset.storageState == AssetStorageState.NoChange);
            asset.storageState = AssetStorageState.Update;

            // This will load a market object in memory
            nToken.cashGroup.loadMarket(market, i + 1, true, blockTime);
            // Remove liquidity from the market
            (int256 assetCash, int256 fCash) = market.removeLiquidity(tokensToRemove);
            totalAssetCash = totalAssetCash.add(assetCash);

            // It is improbable but possible that an fcash asset does not exist if the fCash position for an active liquidity token
            // is zero. This would occur when the nToken has done a lot of lending instead of providing liquidity to the point
            // where the fCash position is exactly zero. This is highly unlikely so instead of adding more logic to handle it we will just
            // fail here. Minting some amount of nTokens will cause the fCash position to be reinstated.
            {
                uint256 ifCashIndex;
                while (newifCashAssets[ifCashIndex].maturity != asset.maturity) {
                    ifCashIndex += 1;
                    require(ifCashIndex < newifCashAssets.length, "Error removing tokens");
                }
                newifCashAssets[ifCashIndex].notional = newifCashAssets[ifCashIndex].notional.add(
                    fCash
                );
            }
        }

        return totalAssetCash;
    }

    /// @notice Sells fCash assets back into the market for cash. Negative fCash assets will decrease netAssetCash
    /// as a result. The aim here is to ensure that accounts can redeem nTokens without having to take on
    /// fCash assets.
    function _sellfCashAssets(
        CashGroupParameters memory cashGroup,
        PortfolioAsset[] memory fCashAssets,
        uint256 blockTime
    ) private returns (int256 totalAssetCash, bool hasResidual) {
        MarketParameters memory market;

        for (uint256 i = 0; i < fCashAssets.length; i++) {
            PortfolioAsset memory asset = fCashAssets[i];
            if (asset.notional == 0) continue;

            (uint256 marketIndex, bool isIdiosyncratic) = DateTime.getMarketIndex(
                cashGroup.maxMarketIndex,
                asset.maturity,
                blockTime
            );

            if (isIdiosyncratic) {
                hasResidual = true;
            } else {
                cashGroup.loadMarket(market, marketIndex, false, blockTime);
                int256 netAssetCash = market.executeTrade(
                    cashGroup,
                    // Use the negative of fCash notional here since we want to net it out
                    asset.notional.neg(),
                    asset.maturity.sub(blockTime),
                    marketIndex
                );

                if (netAssetCash == 0) {
                    // This means that the trade failed
                    hasResidual = true;
                } else {
                    totalAssetCash = totalAssetCash.add(netAssetCash);
                    asset.notional = 0;
                }
            }
        }
    }
}

