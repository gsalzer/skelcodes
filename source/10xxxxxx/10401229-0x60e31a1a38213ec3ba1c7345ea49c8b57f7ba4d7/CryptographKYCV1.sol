// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;


/// @author Guillaume Gonnaud 2020
/// @title Cryptograph KYC header
/// @notice Contain all the events emitted by the Cryptograph KYC
contract CryptographKYCHeaderV1 {

    /// @dev Event fired whenever a wallet address is added or removed from the list of KYCED wallet
    event KYCed(address indexed _user, bool indexed _isValid);

    /// @dev Event fired whenever a new price (in wei) is set for the KYC limit
    event PriceLimit(uint256 indexed _newPrice);
}



/// @author Guillaume Gonnaud 2020
/// @title Cryptograph KYC  Storage Internal
/// @notice Contain all the storage of the Cryptograph KYC  declared in a way that don't generate getters for Proxy use
contract CryptographKYCStorageInternalV1 {

    //Perpetual Altruism, the creator of this smart contract
    address internal perpetualAltruism;

    //The list of wallets that can publish a new price limit  & add/remove wallets from the kyc
    mapping(address => bool) internal authorizedOperators;

    //The price in wei above which a transaction need a KYC. set to 0 to refuse all transactions, to UINT256MAX to allow all.
    uint256 internal priceLimit;

    //The mapping of KYCED users
    mapping(address => bool) internal kycUsers;

}

/// @author Guillaume Gonnaud 2020
/// @title Cryptograph KYC  Storage Internal
/// @notice Contain all the storage of the Cryptograph KYC  declared in a way that don't generate getters for Proxy use
contract CryptographKYCStoragePublicV1 {

    //Perpetual Altruism, the creator of this smart contract
    address public perpetualAltruism;

    //The list of wallets that can publish a new price limit  & add/remove wallets from the kyc
    mapping(address => bool) public authorizedOperators;

    //The price in wei above which a transaction need a KYC. set to 0 to refuse all transactions, to UINT256MAX to allow all.
    uint256 public priceLimit;

    //The mapping of KYCED users
    mapping(address => bool) public kycUsers;
}
