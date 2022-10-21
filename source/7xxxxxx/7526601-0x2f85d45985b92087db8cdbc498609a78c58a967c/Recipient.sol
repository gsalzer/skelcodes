pragma solidity ^0.4.23;

/**
 * @title Recipient interface for CallableToken
 * @dev see https://github.com/ethereum/EIPs/issues/827
 */
interface Recipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external;
    event ReceivedApproval(address indexed user, uint256 value, address indexed token, bytes extraData);
}

