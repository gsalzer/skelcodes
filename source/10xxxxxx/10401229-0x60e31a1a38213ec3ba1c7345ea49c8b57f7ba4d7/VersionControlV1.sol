// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";

/// @author Guillaume Gonnaud 2019
/// @title Version Control Header
/// @notice Contain all the events emitted by the Version Control
contract VersionControlHeaderV1 {
    event VCChangedVersion(uint256 index, address oldCode, address newCode);
    event VCCAddedVersion(uint256 index, address newCode);
}


/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Storage Internal
/// @notice Contain all the storage of TheCryptograph declared in a way that does not generate getters for Proxy use
contract VersionControlStorageInternalV1 {
    address[] public code; //Public to shortcut lookups to it in proxy calls
    address internal controller;
    address internal senate;
}


/// @author Guillaume Gonnaud 2019
/// @title TheCryptograph Storage Public
/// @notice Contain all the storage of TheCryptograph declared in a way that generates getters for Logic use
contract VersionControlStoragePublicV1 {
    address[] public code; //Public for ABI reasons, should be internal for strict gas saving
    address public controller;
    address public senate;
}


