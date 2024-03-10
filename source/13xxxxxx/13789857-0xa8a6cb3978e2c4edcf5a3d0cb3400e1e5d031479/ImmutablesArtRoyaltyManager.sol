// SPDX-License-Identifier: UNLICENSED
// All Rights Reserved

// Contract is not audited.
// Use authorized deployments of this contract at your own risk.

/*
$$$$$$\ $$\      $$\ $$\      $$\ $$\   $$\ $$$$$$$$\  $$$$$$\  $$$$$$$\  $$\       $$$$$$$$\  $$$$$$\       $$$$$$\  $$$$$$$\ $$$$$$$$\
\_$$  _|$$$\    $$$ |$$$\    $$$ |$$ |  $$ |\__$$  __|$$  __$$\ $$  __$$\ $$ |      $$  _____|$$  __$$\     $$  __$$\ $$  __$$\\__$$  __|
  $$ |  $$$$\  $$$$ |$$$$\  $$$$ |$$ |  $$ |   $$ |   $$ /  $$ |$$ |  $$ |$$ |      $$ |      $$ /  \__|    $$ /  $$ |$$ |  $$ |  $$ |
  $$ |  $$\$$\$$ $$ |$$\$$\$$ $$ |$$ |  $$ |   $$ |   $$$$$$$$ |$$$$$$$\ |$$ |      $$$$$\    \$$$$$$\      $$$$$$$$ |$$$$$$$  |  $$ |
  $$ |  $$ \$$$  $$ |$$ \$$$  $$ |$$ |  $$ |   $$ |   $$  __$$ |$$  __$$\ $$ |      $$  __|    \____$$\     $$  __$$ |$$  __$$<   $$ |
  $$ |  $$ |\$  /$$ |$$ |\$  /$$ |$$ |  $$ |   $$ |   $$ |  $$ |$$ |  $$ |$$ |      $$ |      $$\   $$ |    $$ |  $$ |$$ |  $$ |  $$ |
$$$$$$\ $$ | \_/ $$ |$$ | \_/ $$ |\$$$$$$  |   $$ |   $$ |  $$ |$$$$$$$  |$$$$$$$$\ $$$$$$$$\ \$$$$$$  |$$\ $$ |  $$ |$$ |  $$ |  $$ |
\______|\__|     \__|\__|     \__| \______/    \__|   \__|  \__|\_______/ \________|\________| \______/ \__|\__|  \__|\__|  \__|  \__|
$$$$$$$\   $$$$$$\ $$\     $$\  $$$$$$\  $$\    $$$$$$$$\ $$\     $$\
$$  __$$\ $$  __$$\\$$\   $$  |$$  __$$\ $$ |   \__$$  __|\$$\   $$  |
$$ |  $$ |$$ /  $$ |\$$\ $$  / $$ /  $$ |$$ |      $$ |    \$$\ $$  /
$$$$$$$  |$$ |  $$ | \$$$$  /  $$$$$$$$ |$$ |      $$ |     \$$$$  /
$$  __$$< $$ |  $$ |  \$$  /   $$  __$$ |$$ |      $$ |      \$$  /
$$ |  $$ |$$ |  $$ |   $$ |    $$ |  $$ |$$ |      $$ |       $$ |
$$ |  $$ | $$$$$$  |   $$ |    $$ |  $$ |$$$$$$$$\ $$ |       $$ |
\__|  \__| \______/    \__|    \__|  \__|\________|\__|       \__|
$$\      $$\  $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$\  $$$$$$$$\ $$$$$$$\
$$$\    $$$ |$$  __$$\ $$$\  $$ |$$  __$$\ $$  __$$\ $$  _____|$$  __$$\
$$$$\  $$$$ |$$ /  $$ |$$$$\ $$ |$$ /  $$ |$$ /  \__|$$ |      $$ |  $$ |
$$\$$\$$ $$ |$$$$$$$$ |$$ $$\$$ |$$$$$$$$ |$$ |$$$$\ $$$$$\    $$$$$$$  |
$$ \$$$  $$ |$$  __$$ |$$ \$$$$ |$$  __$$ |$$ |\_$$ |$$  __|   $$  __$$<
$$ |\$  /$$ |$$ |  $$ |$$ |\$$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |
$$ | \_/ $$ |$$ |  $$ |$$ | \$$ |$$ |  $$ |\$$$$$$  |$$$$$$$$\ $$ |  $$ |
\__|     \__|\__|  \__|\__|  \__|\__|  \__| \______/ \________|\__|  \__|
*/

pragma solidity ^0.8.0;

/**
 * @author Gutenblock.eth
 * @title ImmutablesArtRoyaltyManager
 * @dev This contract allows to split Ether royalty payments between the
 * Immutables.art contract and an Immutables.art project artist.
 *
 * `ImmutablesArtRoyaltyManager` follows a _pull payment_ model. This means that payments
 * are not automatically forwarded to the accounts but kept in this contract,
 * and the actual transfer is triggered as a separate step by calling the
 * {release} function.
 *
 * The contract is written to serve as an implementation for minimal proxy clones.
 */

import "./Context.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";

contract ImmutablesArtRoyaltyManager is Context, Initializable, ReentrancyGuard {
    using Address for address payable;

    /// @dev The address of the ImmutablesArt contract.
    address public immutablesArtContract;
    /// @dev The projectId of the associated ImmutablesArt project.
    uint256 public immutablesArtProjectId;

    /// @dev The address of the artist.
    address public artist;
    /// @dev The address of the additionalPayee set by the artist.
    address public additionalPayee;
    /// @dev The artist's percentage of the total expressed in basis points
    ///      (1/10,000ths).  The artist can allot up to all of this to
    ///      an additionalPayee.
    uint16 public artistPercent;
    /// @dev The artist's percentage, after additional payee,
    ///      of the total expressed as basis points (1/10,000ths).
    uint16 public artistPercentMinusAdditionalPayeePercent;
    /// @dev The artist's additional payee percentae of the total
    /// @dev expressed in basis points (1/10,000ths).  Valid from 0 to artistPercent.
    uint16 public additionalPayeePercent;

    /// EVENTS

    event PayeeAdded(address indexed account, uint256 percent);
    event PayeeRemoved(address indexed account, uint256 percent);
    event PaymentReleased(address indexed to, uint256 amount);
    event PaymentReleasedERC20(IERC20 indexed token, address indexed to, uint256 amount);
    event PaymentReceived(address indexed from, uint256 amount);

    /**
     * @dev Creates an uninitialized instance of `ImmutablesArtRoyaltyManager`.
     */
    constructor() { }

    /**
     * @dev Initialized an instance of `ImmutablesArtRoyaltyManager`
     */
    function initialize(address _immutablesArtContract, uint256 _immutablesArtProjectId,
                        address _artist, uint16 _artistPercent,
                        address _additionalPayee, uint16 _additionalPayeePercent
                        ) public initializer() {
        immutablesArtContract = _immutablesArtContract;
        immutablesArtProjectId = _immutablesArtProjectId;

        artist = _artist;
        artistPercent = _artistPercent;
        additionalPayee = _additionalPayee;
        additionalPayeePercent = _additionalPayeePercent;
        artistPercentMinusAdditionalPayeePercent = _artistPercent - _additionalPayeePercent;

        emit PayeeAdded(immutablesArtContract, 10000 - artistPercent);
        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
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
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function artistUpdateAddress(address _newArtistAddress) public {
        // only the parent contract and the artist can call this function.
        // the parent contract only calls this function at the request of the artist.
        require(_msgSender() == immutablesArtContract || _msgSender() == artist, "auth");

        // update the artist address
        emit PayeeRemoved(artist, artistPercentMinusAdditionalPayeePercent);
        artist = _newArtistAddress;
        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
    }

    function artistUpdateAdditionalPayeeInfo(address _newAdditionalPayee, uint16 _newPercent) public {
        // only the parent contract and the artist can call this function.
        // the parent contract only calls this function at the request of the artist.
        require(_msgSender() == immutablesArtContract || _msgSender() == artist, "auth");

        // the maximum amount the artist can give to an additional payee is
        // the current artistPercent plus the current additionalPayeePercent.
        require(_newPercent <= artistPercent, "percent too big");

        // Before changing the additional payee information,
        // payout ETH to everyone as indicated when prior payments were made.
        // since we won't know what ERC20 token addresses if any are held,
        // by the contract, we cant force payout on additional payee change.
        release();

        // Change the additional payee and relevant percentages.
        emit PayeeRemoved(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeRemoved(additionalPayee, additionalPayeePercent);
        }

        additionalPayee = _newAdditionalPayee;
        additionalPayeePercent = _newPercent;
        artistPercentMinusAdditionalPayeePercent = artistPercent - _newPercent;

        emit PayeeAdded(artist, artistPercentMinusAdditionalPayeePercent);
        if(additionalPayee != address(0)) {
          emit PayeeAdded(additionalPayee, additionalPayeePercent);
        }
    }

    /**
     * @dev Triggers payout of all ETH royalties.
     */
    function release() public virtual nonReentrant() {
        // checks
        uint256 _startingBalance = address(this).balance;

        // Since this is called when there is a payee change,
        // we do not want to use require and cause a revert
        // if there is no balance.
        if(_startingBalance > 0) {
            // effects
            uint256 _artistAmount = _startingBalance * artistPercentMinusAdditionalPayeePercent / 10000;
            uint256 _additionalPayeeAmount = _startingBalance * additionalPayeePercent / 10000;
            uint256 _contractAmount = _startingBalance - _artistAmount - _additionalPayeeAmount;

            // interactions
            payable(immutablesArtContract).sendValue(_contractAmount);
            emit PaymentReleased(immutablesArtContract, _contractAmount);
            if(artist != address(0) && _artistAmount > 0) {
              payable(artist).sendValue(_artistAmount);
              emit PaymentReleased(artist, _artistAmount);
            }
            if(additionalPayee != address(0) && _additionalPayeeAmount > 0) {
              payable(additionalPayee).sendValue(_additionalPayeeAmount);
              emit PaymentReleased(additionalPayee, _additionalPayeeAmount);
            }
        }
    }

    /**
     * @dev Triggers payout of all ERC20 royalties.
     */
    function releaseERC20(IERC20 token) public virtual nonReentrant() {
        // checks
        uint256 _startingBalance = token.balanceOf(address(this));
        require(_startingBalance > 0, "no tokens");

        // effects
        uint256 _artistAmount = _startingBalance * artistPercentMinusAdditionalPayeePercent / 10000;
        uint256 _additionalPayeeAmount = _startingBalance * additionalPayeePercent / 10000;
        uint256 _contractAmount = _startingBalance - _artistAmount - _additionalPayeeAmount;

        // interactions
        SafeERC20.safeTransfer(token, immutablesArtContract, _contractAmount);
        emit PaymentReleasedERC20(token, immutablesArtContract, _contractAmount);
        if(artist != address(0) && _artistAmount > 0) {
          SafeERC20.safeTransfer(token, artist, _artistAmount);
          emit PaymentReleasedERC20(token, artist, _artistAmount);
        }
        if(additionalPayee != address(0) && _additionalPayeeAmount > 0) {
          SafeERC20.safeTransfer(token, additionalPayee, _additionalPayeeAmount);
          emit PaymentReleasedERC20(token, additionalPayee, _additionalPayeeAmount);
        }
    }
}

