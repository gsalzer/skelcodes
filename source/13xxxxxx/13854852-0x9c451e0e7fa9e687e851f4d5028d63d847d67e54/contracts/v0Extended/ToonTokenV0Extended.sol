// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../v0/ToonTokenV0.sol";
import "./Obligations.sol";

/**
 * This contract locks newly minted bonus tokens for a specific amount of time
 * or until the current price per token reaches the specified price target.
 *
 * Technical considerations
 *
 * The rationale for this contract is to reduce purchase gas costs, executing
 * mint+lock procedure automatically, regularly and rarely:
 * first, it increments the reserve counters that keep the number of bonus tokens
 * to be minted (see `maintainerBonusReserve` and and `bountyBonusReserve`),
 * without physically minting these tokens;
 * second, it mints+locks them automatically when any of these two
 * reserve counters surpasses the internal threshold (`_UNMINTED_RESERVE_LIMIT`).
 *
 * This limit postpones automatic locking of newly minted bonus tokens ONLY to
 * reduce gas overhead for token buyers; it does not put any restrictions on
 * this process, so these reserve counters may be flushed by calling
 * `mintAndLockMaintainerBonusReserves`
 * and/or `mintAndLockBountyBonusReserves` directly.
 */
contract ToonTokenV0Extended is ToonTokenV0, Obligations {
    /**
     * Internal threshold used to batch bonus tokens minting+locking.
     *
     * Typically, bonus tokens are minted upon every purchase (occurred after
     * the price per token crosses the corresponding thresholds),
     * however this gives an unwanted overhead in purchase gas costs. To avoid
     * more gas costs which arise when we start locking newly minted tokens
     * via obligations (see `lockTokens` for details), we keep the number of
     * bonus tokens to be minted later using the internal reserve counters
     * (see `maintainerBonusReserve` and `bountyBonusReserve`) without physically
     * minting these tokens, and mint and immediately lock them as soon as
     * any of these reserve counters surpasses this limit.
     *
     * This limit postpones automatic locking of newly minted bonus tokens ONLY
     * to reduce gas overhead for token buyers; it does not put any restrictions
     * on this process, so these reserve counters may be flushed by calling
     * `mintAndLockMaintainerBonusReserves`
     * and/or `mintAndLockBountyBonusReserves` directly.
     */
    uint256 private constant _UNMINTED_RESERVE_LIMIT = 10000 * 10**18;

    /**
     * Internal reserve counter used to track maintainer bonus tokens to be minted
     * and locked later (either automatically when it surpasses the reserve
     * limit defined by the `_UNMINTED_RESERVE_LIMIT`, or manually by calling
     * `mintAndLockMaintainerBonusReserves` method directly)
     */
    uint256 public maintainerBonusReserve;

    /**
     * Internal reserve counter used to track bounty bonus tokens to be minted
     * and locked later (either automatically when it surpasses the reserve
     * limit defined by the `_UNMINTED_RESERVE_LIMIT`, or manually by calling
     * `mintAndLockBountyBonusReserves` method directly).
     */
    uint256 public bountyBonusReserve;

    /**
     * Represents a reference price that may be used as an obligation target
     * price for locking newly minted bounty tokens.
     * When bounty tokens are being minted and immediately locked by
     * obligation, this value is used as a target price if being more then
     * the current price per token. This reference price may be set by the current
     * maintainer only.
     *
     * `BountyObligationReferencePriceUpdated` event is emitted when a new
     * reference price is set by the current maintainer.
     */
    uint256 public bountyObligationReferencePrice;

    /**
     * Emitted when the  bounty obligation reference price is being updated by
     * the current maintainer.
     */
    event BountyObligationReferencePriceUpdated(uint256 referencePrice);

    /**
     * The current maintainer may set a reference price to be used as an
     * obligation target price for locking newly minted bounty tokens. Reference
     * price must be more  than twice the current price per token when setting.
     * Reference price may be used as a target price only until being more than
     * the current price per token AND being less than the twice current price
     * per token at the time the new tokens are being minted.
     */
    function setBountyObligationReferencePrice(uint256 referencePrice)
        external
        onlyMaintainer
    {
        require(
            referencePrice > (currentPricePerToken * 2),
            "twice the current price"
        );
        bountyObligationReferencePrice = referencePrice;

        emit BountyObligationReferencePriceUpdated(referencePrice);
    }

    /**
     * Creates an obligation which locks the given `amount` of tokens by
     * transferring them from the caller's balance to this contract address
     * and holds them until the given `releaseTime` in the future OR the given
     * `targetPrice` per token are reached; an obligation may be paid off
     * to the given `recipient`'s address after by calling `payOffObligation`.
     *
     * Emits `ObligationCreated` on success.
     *
     * Transaction is being reverted if the caller's balance does not cover
     * the given `amount` of tokens.
     *
     * Tokens may be released by calling `payOffObligation`.
     */
    function lockTokens(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) external {
        _createObligation(
            _msgSender(),
            amount,
            recipient,
            releaseTime,
            targetPrice
        );
    }

    /**
     * Mints and locks all maintainer bonus tokens kept by the
     * `maintainerBonusReserve` reserve counter, if any.
     *
     * Tokens are being locked by an obligation that holds
     * the tokens for 365 days (≈1 year) OR until the current price per token is
     * doubled of the price at the time the obligation is being created.
     *
     * An obligation may be paid off to the address specified
     * by the `maintainerWallet` at the time the obligation has being created
     * by calling `payOffObligation`.
     *
     * See `lockTokens` for details.
     */
    function mintAndLockMaintainerBonusReserves() public {
        _mint(maintainerWallet, maintainerBonusReserve);
        _createObligation(
            maintainerWallet,
            maintainerBonusReserve,
            maintainerWallet,
            block.timestamp + 365 days, // ≈1 year
            currentPricePerToken * 2
        );
        maintainerBonusReserve = 0;
    }

    /**
     * Mints and locks all maintainer bonus tokens kept by the
     * `bountyBonusReserve` reserve counter, if any.
     *
     * Tokens are being locked by an obligation that holds
     * the tokens for 36500 days (≈forever) OR until the current price per token is
     * doubled of the price at the time the obligation is being created.
     *
     * An obligation may be paid off to the address specified
     * by the `bountyWallet` at the time the obligation has being created
     * by calling `payOffObligation`.
     *
     * See `lockTokens` for details.
     */
    function mintAndLockBountyBonusReserves() public {
        _mint(bountyWallet, bountyBonusReserve);

        uint256 targetPrice = currentPricePerToken * 2;
        if (currentPricePerToken < bountyObligationReferencePrice) {
            targetPrice = Math.min(bountyObligationReferencePrice, targetPrice);
        }

        _createObligation(
            bountyWallet,
            bountyBonusReserve,
            bountyWallet,
            // ≈forever, reaching target price is
            // the only way to release the tokens
            block.timestamp + 36500 days,
            targetPrice
        );
        bountyBonusReserve = 0;
    }

    /**
     * Returns the amount of tokens in existence.
     *
     * Since there are tokens that are kept by reserve counters (see
     * `maintainerBonusReserve` and `bountyBonusReserve`) and not yet physically
     * minted, we must adjust the total supply by adding the numbers from these
     * counters so that the state of this contract treats these tokens are like
     * being minted.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return
            super.totalSupply() + maintainerBonusReserve + bountyBonusReserve;
    }

    /**
     * Required by `Obligations` to transfer the `amount` of tokens from `sender`
     * to `recipient`
     */
    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        _transfer(sender, recipient, amount);
    }

    /**
     * Called when the `amount` of maintainer bonus tokens must be minted.
     *
     * Increments the internal reserve counter without physically minting+locking
     * the tokens to avoid high gas costs. Initiates mint+lock as soon as this
     * counter surpasses the internal reserve limit (`_UNMINTED_RESERVE_LIMIT`)
     *
     * See `mintAndLockMaintainerBonusReserves` for details.
     */
    function _mintMaintainerBonus(uint256 maintainerBonusTokensAmount)
        internal
        virtual
        override
    {
        maintainerBonusReserve += maintainerBonusTokensAmount;

        if (maintainerBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockMaintainerBonusReserves();
        }
    }

    /**
     * Called when the `amount` of maintainer bonus tokens must be minted.
     *
     * Increments the internal reserve counter without physically minting+locking
     * the tokens to avoid high gas costs. Initiates mint+lock as soon as this
     * counter surpasses the internal reserve limit (`_UNMINTED_RESERVE_LIMIT`)
     *
     * See `mintAndLockBountyBonusReserves` for details.
     */
    function _mintBountyBonus(uint256 bountyBonusTokensAmount)
        internal
        virtual
        override
    {
        bountyBonusReserve += bountyBonusTokensAmount;

        if (bountyBonusReserve > _UNMINTED_RESERVE_LIMIT) {
            mintAndLockBountyBonusReserves();
        }
    }

    /**
     * Required by `Obligations` to retrieve the current price per token
     */
    function _currentPricePerToken()
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return currentPricePerToken;
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[47] private __gap;
}

