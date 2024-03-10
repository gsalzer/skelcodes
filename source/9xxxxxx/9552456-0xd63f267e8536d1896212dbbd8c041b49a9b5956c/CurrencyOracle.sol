pragma solidity ^0.4.24;

import "oraclizeAPI.sol";
import "Ownable.sol";
import "IOracle.sol";
import "Authorization.sol";
import "Pausable.sol";
import "SafeMath.sol";

contract CurrencyOracle is usingOraclize, IOracle, Ownable, Pausable{
    using SafeMath for uint256;

    string public oracleURL;
    string public oracleQueryType = "URL";

    mapping (bytes32 => uint256) public requestIds;
    mapping (bytes32 => bool) public ignoreRequestIds;

    uint256 public latestUpdate;
    uint256 public latestScheduledUpdate;
    uint256 public staleTime = 6 hours;
    uint256 public sanityBounds = 20*10**16;
    uint256 public gasLimit = 100000;
    uint256 public oraclizeTimeTolerance = 5 minutes;

    uint256 private price;
    uint256 public min_price;
    uint256 public max_price;

    mapping (address => bool) public admin;

    event LogPriceUpdated(uint256 _price, uint256 _oldPrice, bytes32 _queryId, uint256 _time);
    event LogNewOraclizeQuery(uint256 _time, bytes32 _queryId, string _query);
    event LogStalePriceUpdate(bytes32 _queryId, uint256 _time, string _result);
    event LogAdminSet(address _admin, bool _valid, uint256 _time);

    modifier isAdminOrOwner {
        require(admin[msg.sender] || msg.sender == owner(), "Address is not admin or owner");
        _;
    }

    constructor() payable public{
        oraclize_setCustomGasPrice(50*10**9);
    }

    function __callback(bytes32 _requestId, string _result) public
    { 
        require(msg.sender == oraclize_cbAddress(), "Only Oraclize can access this method");
        require(!paused, "Oracle is paused");
        require(!ignoreRequestIds[_requestId], "Ignoring requestId");
        if (requestIds[_requestId] < latestUpdate) {
            emit LogStalePriceUpdate(_requestId, requestIds[_requestId], _result);
            return;
        }

        require(requestIds[_requestId] >= latestUpdate, "Result is stale");
        require(requestIds[_requestId] <= now + oraclizeTimeTolerance, "Result is early");

        uint256 newPrice = parseInt(_result, 18);
        uint256 bound = price.mul(sanityBounds).div(10**18);
        if (latestUpdate != 0) {
          require(newPrice <= price.add(bound), "Result is too large");
          require(newPrice >= price.sub(bound), "Result is too small");
        }
        require (checkPrice(newPrice), "newPrice checkPrice fail");

        latestUpdate = requestIds[_requestId];
        emit LogPriceUpdated(newPrice, price, _requestId, latestUpdate);
        price = newPrice;
    }

    function schedulePriceUpdatesFixed(uint256[] _times) payable isAdminOrOwner public {
        bytes32 requestId;
        uint256 maximumScheduledUpdated;
        if (_times.length == 0) {
            require(oraclize_getPrice(oracleQueryType, gasLimit) <= address(this).balance, "Insufficient Funds");
            requestId = oraclize_query(oracleQueryType, oracleURL, gasLimit);
            requestIds[requestId] = now;
            maximumScheduledUpdated = now;
            emit LogNewOraclizeQuery(now, requestId, oracleURL);
        } else {
            require(oraclize_getPrice(oracleQueryType, gasLimit) * _times.length <= address(this).balance, "Insufficient Funds");
            for (uint256 i = 0; i < _times.length; i++) {
                require(_times[i] >= now, "Past scheduling is not allowed and scheduled time should be absolute timestamp");
                requestId = oraclize_query(_times[i], oracleQueryType, oracleURL, gasLimit);
                requestIds[requestId] = _times[i];
                if (maximumScheduledUpdated < requestIds[requestId]) {
                    maximumScheduledUpdated = requestIds[requestId];
                }
                emit LogNewOraclizeQuery(_times[i], requestId, oracleURL);
            }
        }
        if (latestScheduledUpdate < maximumScheduledUpdated) {
            latestScheduledUpdate = maximumScheduledUpdated;
        }
    }

    function schedulePriceUpdatesRolling(uint256 _startTime, uint256 _interval, uint256 _iters) payable isAdminOrOwner public {
        bytes32 requestId;
        require(_interval > 0, "Interval between scheduled time should be greater than zero");
        require(_iters > 0, "No iterations specified");
        require(_startTime >= now, "Past scheduling is not allowed and scheduled time should be absolute timestamp");
        require(oraclize_getPrice(oracleQueryType, gasLimit) * _iters <= address(this).balance, "Insufficient Funds");
        for (uint256 i = 0; i < _iters; i++) {
            uint256 scheduledTime = _startTime + (i * _interval);
            requestId = oraclize_query(scheduledTime, oracleQueryType, oracleURL, gasLimit);
            requestIds[requestId] = scheduledTime;
            emit LogNewOraclizeQuery(scheduledTime, requestId, oracleURL);
        }
        if (latestScheduledUpdate < requestIds[requestId]) {
            latestScheduledUpdate = requestIds[requestId];
        }
    }

    function setPrice(uint256 _price) isAdminOrOwner public {
        require (checkPrice(_price), "_price checkPrice fail");

        emit LogPriceUpdated(_price, price, 0, now);
        price = _price;
        latestUpdate = now;
    }

    function setGasLimit(uint256 _gasLimit) isAdminOrOwner public {
        gasLimit = _gasLimit;
    }

    function setIgnoreRequestIds(bytes32[] _requestIds, bool[] _ignore) isAdminOrOwner public {
        require(_requestIds.length == _ignore.length, "Incorrect parameter lengths");
        for (uint256 i = 0; i < _requestIds.length; i++) {
            ignoreRequestIds[_requestIds[i]] = _ignore[i];
        }
    }
    
    function setOracleURL(string _oracleURL) isAdminOrOwner public {
        oracleURL = _oracleURL;
    }

    function setOracleQueryType(string _oracleQueryType) isAdminOrOwner public {
        oracleQueryType = _oracleQueryType;
    }

    function setSanityBounds(uint256 _sanityBounds) isAdminOrOwner public {
        sanityBounds = _sanityBounds;
    }

    function setOraclizeTimeTolerance(uint256 _oraclizeTimeTolerance) isAdminOrOwner public {
        oraclizeTimeTolerance = _oraclizeTimeTolerance;
    }

    function getCurrencyAddress() external view returns(address) {
        return 0x00;
    }

    function getCurrencySymbol() external view returns(bytes32 result) {
        return bytes32("");
    }

    function getCurrencyDenominated() external view returns(bytes32) {
        return bytes32("USD");
    }

    function getPrice(uint256 _amount) external view returns(uint256) {
        return decimalMul(price, _amount,  10 ** 18);
    }

    function decimalMul(uint256 x, uint256 y, uint256 DECIMALS) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), DECIMALS / 2) / DECIMALS;
    }

    function decimalDiv(uint256 x, uint256 y, uint256 DECIMALS) internal pure returns (uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, DECIMALS), y / 2) / y;
    }

    function drainContract() external isAdminOrOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setAdmin(address _admin, bool _valid) onlyOwner public {
        admin[_admin] = _valid;
        emit LogAdminSet(_admin, _valid, now);
    }

    function setMinPrice (uint256 _minPrice) external isAdminOrOwner returns(bool res) {
        min_price = _minPrice;
        return true;
    }
    
    function setMaxPrice (uint256 _maxPrice) external isAdminOrOwner returns(bool res) {
        max_price = _maxPrice;
        return true;
    }

    function checkPrice(uint256 _price) public returns(bool) {
        return _price >= min_price && _price <= max_price;
    }
}
