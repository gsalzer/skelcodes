// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

/**
 * Implements time-/price-based obligations.
 *
 * An obligation locks a given amount of tokens by holding them on this
 * contract address and may be asked to release them upon reaching either
 * a given time in the future OR a given price per token by transferring them
 * to a given recipient's address.
 */
abstract contract Obligations {
    /**
     * Gas efficient obligations' storage.
     *
     * An obligation locks the given amount of tokens by holding them on this
     * contract address and may be asked to release them upon reaching either
     * a given release time in the future OR a given target price per token
     * by transferring them to a given recipient's address.
     *
     * This mapping efficiently stores all this data in the following order:
     *
     *  `recipient => release time in the future => target price per token => amount`
     *
     * Thus, each obligation may be referred by the `recipient` + `releaseTime` +
     * `targetPrice` combination rather than any sort of internal identifiers.
     */
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _obligations;

    /**
     * Emitted when the new obligation is created, locking the `amount` of
     * tokens until the target `time` OR the target `price` per token are
     * reached, and may be paid off to the `recipient`'s address after.
     */
    event ObligationCreated(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    /**
     * Emitted when the existing obligation is paid off, meaning that the
     * `amount` of tokens has been transferred to the `recipient`'s address.
     */
    event ObligationPaidOff(
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    );

    /**
     * Releases the tokens locked by `recipient` + `releaseTime` + `targetPrice`
     * obligation by transferring them to the `recipient`'s address if and only
     * if the current time (defined by block.timestamp) has reached
     * obligation's `releaseTime` OR the current price per token (defined by
     * `_currentPricePerToken`) has reached the obligation's `targetPrice`.
     *
     * Emits `ObligationPaidOff` on success.
     *
     * Note that each obligation is referred by the `recipient` + `releaseTime` +
     * `targetPrice` combined, so it is impossible to spoof this method by changing
     * either `recipient` or `releaseTime` or `targetPrice`.
     */
    function payOffObligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public {
        require(
            block.timestamp >= releaseTime ||
                _currentPricePerToken() >= targetPrice,
            "too early"
        );
        require(
            _obligations[recipient][releaseTime][targetPrice] > 0,
            "nothing to pay off"
        );

        uint256 amount = _obligations[recipient][releaseTime][targetPrice];
        _obligations[recipient][releaseTime][targetPrice] = 0;

        _transferTokens(address(this), recipient, amount);
        emit ObligationPaidOff(amount, recipient, releaseTime, targetPrice);
    }

    /**
     * Returns the amount of tokens locked by the obligation (if any) referred
     * by the `recipient` + `releaseTime` + `targetPrice` combined.
     */
    function obligation(
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) public view returns (uint256) {
        return _obligations[recipient][releaseTime][targetPrice];
    }

    /**
     * To hold tokens, this extension transfers them to this contract address.
     * This method must implement actual transfer.
     */
    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual;

    /**
     * Tokens may be held until a specific price per token is reached. This
     * method must return the current price per token.
     */
    function _currentPricePerToken() internal virtual returns (uint256);

    /**
     * Creates an obligation which locks the given `amount` of tokens by
     * transferring them from the `account`'s address to this contract address
     * and holds them  until the given `releaseTime` in the future OR the given
     * `targetPrice` per token are reached; an obligation may be paid off
     * to the given `recipient`'s address after by calling `payOffObligation`.
     *
     * Emits `ObligationCreated` on success.
     *
     * Transaction is being reverted if the `account`'s balance does not cover
     * the given `amount` of tokens.
     *
     * Tokens may be released by calling `payOffObligation`.
     */
    function _createObligation(
        address account,
        uint256 amount,
        address recipient,
        uint256 releaseTime,
        uint256 targetPrice
    ) internal {
        _transferTokens(account, address(this), amount);
        _obligations[recipient][releaseTime][targetPrice] += amount;
        emit ObligationCreated(
            _obligations[recipient][releaseTime][targetPrice],
            recipient,
            releaseTime,
            targetPrice
        );
    }

    // Reserved storage space to allow for layout changes in the future.
    // solhint-disable-next-line ordering
    uint256[49] private __gap;
}

