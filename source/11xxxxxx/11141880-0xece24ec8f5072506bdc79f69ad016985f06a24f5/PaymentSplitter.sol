// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import './Context.sol';
import './SafeMath.sol';

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract PaymentSplitter is Context {
    using SafeMath for uint256;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor () public {

      // 1000 shares total. 10 shares = 1%
      _addPayee(0xA81eac3009bD6E6cCE36602d6851fDA789dDC3BB, 400);
      _addPayee(0xF76Df69C8bf3bcFdBc46F69773749f2E308Fc2D1, 150);
      _addPayee(0xFaDED72464D6e76e37300B467673b36ECc4d2ccF, 130);
      _addPayee(0xEa9F106172697E3E363f9f4B292f73b1217b2a88, 100);
      _addPayee(0x7e7e2bf7EdC52322ee1D251432c248693eCd9E0f, 55);
      _addPayee(0x3DCa07E16B2Becd3eb76a9F9CE240B525451f887, 30);
      _addPayee(0x20404Bd50e8640424a7D3BF41B3417C9AE765507, 30);
      _addPayee(0x82eE15e7C0c923e512eB0C554a50E08254EbD660, 25);
      _addPayee(0xFB015608e84b32f44361429B92B6d62B937e2015, 20);
      _addPayee(0xFCd6AD49134A0755923c096382e5fc3b80Cb21b5, 10);
      _addPayee(0xfD2D983aF16dA2965F5654a0166b8e33Cc3Cf5F1, 10);
      _addPayee(0x6e43d04A2c8b8Dc3a6FA9DD35711559B493543d1, 10);
      _addPayee(0x37fc5190c725F448fa9D88DE87843884164a684b, 10);
      _addPayee(0x4425eD8684f3A6C1093E27FD44020B3917f29227, 10);
      _addPayee(0x3b1356CA97A31b3a2DAd0e901b9F73380e00B66D, 10);

    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive () external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance.add(_totalReleased);
        uint256 payment = totalReceived.mul(_shares[account]).div(_totalShares).sub(_released[account]);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] = _released[account].add(payment);
        _totalReleased = _totalReleased.add(payment);

        account.transfer(payment);
        emit PaymentReleased(account, payment);
    }

    function releaseAll() external virtual {
        for (uint256 i = 0; i < _payees.length; i++) {
            release(address(uint160(_payees[i])));
        }
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account, shares_);
    }
}
