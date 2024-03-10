pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../contracts_common/src/Libraries/SigUtil.sol";
import "../contracts_common/src/BaseWithStorage/Admin.sol";


contract PurchaseValidator is Admin {
    address private _signingWallet;

    // A parallel-queue mapping to nonces.
    mapping(address => mapping(uint128 => uint128)) public queuedNonces;

    /// @notice Function to get the nonce for a given address and queue ID
    /// @param _buyer The address of the starterPack purchaser
    /// @param _queueId The ID of the nonce queue for the given address.
    /// The default is queueID=0, and the max is queueID=2**128-1
    /// @return uint128 representing the requestied nonce
    function getNonceByBuyer(address _buyer, uint128 _queueId) external view returns (uint128) {
        return queuedNonces[_buyer][_queueId];
    }

    /// @notice Check if a purchase message is valid
    /// @param buyer The address paying for the purchase & receiving tokens
    /// @param catalystIds The catalyst IDs to be purchased
    /// @param catalystQuantities The quantities of the catalysts to be purchased
    /// @param gemIds The gem IDs to be purchased
    /// @param gemQuantities The quantities of the gems to be purchased
    /// @param nonce The current nonce for the user. This is represented as a
    /// uint256 value, but is actually 2 packed uint128's (queueId + nonce)
    /// @param signature A signed message specifying tx details
    /// @return True if the purchase is valid
    function isPurchaseValid(
        address buyer,
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemIds,
        uint256[] memory gemQuantities,
        uint256 nonce,
        bytes memory signature
    ) public returns (bool) {
        require(_checkAndUpdateNonce(buyer, nonce), "INVALID_NONCE");
        require(_validateGemAmounts(catalystIds, catalystQuantities, gemQuantities), "INVALID_GEMS");
        bytes32 hashedData = keccak256(abi.encodePacked(catalystIds, catalystQuantities, gemIds, gemQuantities, buyer, nonce));

        address signer = SigUtil.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);
        return signer == _signingWallet;
    }

    /// @notice Get the wallet authorized for signing purchase-messages.
    /// @return the address of the signing wallet
    function getSigningWallet() external view returns (address) {
        return _signingWallet;
    }

    /// @notice Update the signing wallet address
    /// @param newSigningWallet The new address of the signing wallet
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "SENDER_NOT_ADMIN");
        _signingWallet = newSigningWallet;
    }

    /// @dev Function for validating the nonce for a user.
    /// @param _buyer The address for which we want to check the nonce
    /// @param _packedValue The queueId + nonce, packed together.
    /// EG: for queueId=42 nonce=7, pass: "0x0000000000000000000000000000002A00000000000000000000000000000007"
    function _checkAndUpdateNonce(address _buyer, uint256 _packedValue) private returns (bool) {
        uint128 queueId = uint128(_packedValue / 2**128);
        uint128 nonce = uint128(_packedValue % 2**128);
        uint128 currentNonce = queuedNonces[_buyer][queueId];
        if (nonce == currentNonce) {
            queuedNonces[_buyer][queueId] = currentNonce + 1;
            return true;
        }
        return false;
    }

    /// @dev Function to ensure the gem amounts requested are valid.
    /// @param catalystIds An array of Ids. Order cannot be assumed to be consistent.
    /// @param catalystQuantities The quantitiy of each catalyst Id
    /// @param gemQuantities The quantitiy of each type of gem.
    /// @return bool - whether or not gem amounts are valid
    function _validateGemAmounts(
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemQuantities
    ) private returns (bool) {
        uint256 maxGemsAllowed;
        uint256 requestedGems;
        for (uint256 i = 0; i < catalystQuantities.length; i++) {
            require(catalystIds[i] < 4, "ID_OUT_OF_BOUNDS");
            maxGemsAllowed += catalystQuantities[i] * (catalystIds[i] + 1);
        }
        for (uint256 i = 0; i < gemQuantities.length; i++) {
            requestedGems += gemQuantities[i];
        }
        return (requestedGems <= maxGemsAllowed);
    }

    constructor(address initialSigningWallet) public {
        _signingWallet = initialSigningWallet;
    }
}

