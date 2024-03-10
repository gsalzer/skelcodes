pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
contract TradeProfile {
    event LogTraderTradingTransaction(string tradingTx);
    event LogAggregatedFollowersTradingTransaction(bytes32 aggregatedTxsHash);

    mapping(address=>bool) public errand;
    address public admin;
    uint256 public strategyId;
    constructor(uint256 _strategyId) public {
        strategyId = _strategyId;
        admin = msg.sender;
    }

    /**
    * @dev Log the trader's trading transactions.
    * @param _tradingTxs string Trading transactions in JSON format.
    */
    function logTraderTradingTx(string[] _tradingTxs) public {
        require(errand[msg.sender]);
        for(uint i=0; i<_tradingTxs.length; i++) {
            emit LogTraderTradingTransaction(_tradingTxs[i]);
        }
    }

    function newErrand(address _newErrand) public {
      require(msg.sender == admin);
      errand[_newErrand] = true;
    }

    function removeErrand(address _errand) public {
      require(msg.sender == admin);
      errand[_errand] = false;
    }

    /**
    * @dev Log the followers' trading transactions.
    * @param _aggregatedTxsHash bytes32 Hash of aggregation of followers' trading transactions.
    */
    function logFollowerTradingTx(bytes32 _aggregatedTxsHash) public {
        require(errand[msg.sender]);
        emit LogAggregatedFollowersTradingTransaction(_aggregatedTxsHash);
    }
}
