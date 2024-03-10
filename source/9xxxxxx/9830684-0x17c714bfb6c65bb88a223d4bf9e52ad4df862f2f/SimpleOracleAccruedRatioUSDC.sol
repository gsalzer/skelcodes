pragma solidity ^0.4.24;

contract SimpleOracleAccruedRatioUSDC {
    address public owner;
    uint256 public accruedRatioUSDC;

    // event QueryEvent(bytes32 id, string query);

    constructor(uint256 _accruedRatioUSDC) {
        owner = msg.sender;
        accruedRatioUSDC = _accruedRatioUSDC;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function set(uint256 _accruedRatioUSDC) onlyOwner {
        accruedRatioUSDC = _accruedRatioUSDC;
    }

    function query() returns(uint256) {
        // QueryEvent(msg.sender, block.number);
        return accruedRatioUSDC;
    }
}

