pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken

interface TokenRecipientInterface {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
}

