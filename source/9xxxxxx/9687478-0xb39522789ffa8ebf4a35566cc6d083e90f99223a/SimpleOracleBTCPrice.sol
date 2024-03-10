pragma solidity ^0.4.24;

contract SimpleOracleBTCPrice {
    address public owner;
    uint256 public amountStableTokenPerBTC;

    // event QueryEvent(bytes32 id, string query);

    constructor(uint256 _amountStableTokenPerBTC) {
        owner = msg.sender;
        amountStableTokenPerBTC = _amountStableTokenPerBTC;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function set(uint256 _amountStableTokenPerBTC) onlyOwner {
        amountStableTokenPerBTC = _amountStableTokenPerBTC;
    }

    function query() returns(uint256) {
        // QueryEvent(msg.sender, block.number);
        return amountStableTokenPerBTC;
    }
}

