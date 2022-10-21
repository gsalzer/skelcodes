pragma solidity ^0.5.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IManagement.sol";
import "./Constants.sol";
import "./ICoinExchangeRates.sol";


/*solium-disable-next-line*/
contract CoinExchangeRates is ICoinExchangeRates, IManagement, Constants, Ownable {
    using SafeMath for uint256;

    uint256 private blobCoinPrice_;

    address[] private permittedCoinsAddresses_;

    mapping(address => uint256) public stableCoinsPrices;
    mapping(address => uint256) public stableCoinsDecimals;
    mapping(address => uint256) public priceUpdatedAt;
    mapping(address => uint256) public stableCoinsToProportion;

    mapping(address => uint256) public permittedTokensToId;

    modifier requirePermission(uint256 _permissionBit) {
        require(
            hasPermission(msg.sender, _permissionBit),
            ERROR_ACCESS_DENIED
        );
        _;
    }

    event PriceUpdated(uint256 newPrice);

    constructor(uint256 _blobCoinPrice)
    public
    {
        blobCoinPrice_ = _blobCoinPrice;
        permittedCoinsAddresses_.push(address(0));
    }

    // 5 00000
    function setBlobCoinPrice(uint256 _blobCoinPrice)
    public
    requirePermission(CAN_REGISTER_COINS)
    {
        blobCoinPrice_ = _blobCoinPrice;
        emit PriceUpdated(_blobCoinPrice);
    }

    function setCoinsPricesInUSD(
        address[] memory _coinsAddresses,
        uint256[] memory _prices
    )
    public
    requirePermission(CAN_REGISTER_COINS)
    returns(bool)
    {
        require(
            _coinsAddresses.length == _prices.length,
            ERROR_WRONG_AMOUNT
        );

        for (uint256 i = 0; i < _coinsAddresses.length; i++) {
            setCoinPrice(_coinsAddresses[i], _prices[i]);
        }
        return true;
    }

    function setCoinsCoverageProportion(
        address[] memory _coinsAddresses,
        uint256[] memory _percentageProportion
    )
    public
    requirePermission(CAN_REGISTER_COINS)
    returns(bool)
    {
        require(
            _coinsAddresses.length == _percentageProportion.length,
            ERROR_WRONG_AMOUNT
        );
        uint256 totalProportion;
        for (uint256 i = 0; i < _coinsAddresses.length; i++) {
            require(
                hasPermission(_coinsAddresses[i], PERMITTED_COINS),
                ERROR_ACCESS_DENIED
            );
            stableCoinsToProportion[
            _coinsAddresses[i]
            ] = _percentageProportion[i];
            totalProportion = totalProportion.add(_percentageProportion[i]);
        }
        require(totalProportion == PERCENTS_ABS_MAX, ERROR_WRONG_AMOUNT);
        return true;
    }

    function calculateUSDByBlobs(uint256 _blobsAmount)
    public
    view
    returns(uint256)
    {
        uint256 coefficientWithoutFee = PERCENTS_ABS_MAX
        .sub(getFeePercentage());

        return _blobsAmount
        .mul(blobCoinPrice())
        .mul(coefficientWithoutFee)
        .div(PERCENTS_ABS_MAX);
    }

    function calculateUsdByCoin(
        address _stableCoinAddress,
        uint256 _coinsAmount
    )
    public
    view
    returns (uint256)
    {
        uint256 coinDecimals = stableCoinsDecimals[_stableCoinAddress];
        uint256 coinsAmount = _coinsAmount;
        if (coinDecimals < 18) {
            coinsAmount = _coinsAmount.mul(1e18).div(10 ** coinDecimals);
        }
        return getCoinPrice(_stableCoinAddress).mul(coinsAmount);
    }

    function calculateCoinsAmountByUSD(
        uint256 _usdAmount
    )
    public
    view
    returns (address[] memory, uint256[] memory)
    {
        uint256[] memory coinsAmount = new uint[](
            permittedCoinsAddresses_.length
        );
        for (uint256 i = 1; i < permittedCoinsAddresses_.length; i++) {
            coinsAmount[i] = _usdAmount
            .mul(10**stableCoinsDecimals[permittedCoinsAddresses_[i]])
            .mul(stableCoinsToProportion[permittedCoinsAddresses_[i]])
            .div(getCoinPrice(permittedCoinsAddresses_[i]))
            .div(PERCENTS_ABS_MAX);
        }
        return (permittedCoinsAddresses_, coinsAmount);
    }

    function calculateBlobsAmount(
        address _stableCoinAddress,
        uint256 _coinsAmount
    )
    public
    view
    returns (uint256)
    {

        return calculateUsdByCoin(_stableCoinAddress, _coinsAmount)
        .div(blobCoinPrice());
    }

    function coinPriceUpdatedAt(address _stableCoinAddress)
    public
    view
    returns(uint256)
    {
        return priceUpdatedAt[_stableCoinAddress];
    }

    function getCoinPrice(address _stableCoinAddress)
    public
    view
    returns(uint256)
    {
        return stableCoinsPrices[_stableCoinAddress];
    }

    function permittedCoinsAddresses()
    public
    view
    returns (address[] memory)
    {
        return permittedCoinsAddresses_;
    }

    function blobCoinPrice()
    public
    view
    returns (uint256)
    {
        return blobCoinPrice_;
    }

    function setCoinPrice(address _stableCoinAddress, uint256 _price)
    internal
    {
        require(
            hasPermission(_stableCoinAddress, PERMITTED_COINS),
            ERROR_ACCESS_DENIED
        );
        stableCoinsPrices[_stableCoinAddress] = _price;
        priceUpdatedAt[_stableCoinAddress] = block.timestamp;
    }

    function internalSetPermissionsForCoins(
        address _address,
        bool _value,
        uint256 _decimals
    )
    internal
    {
        stableCoinsDecimals[_address] = _decimals;
        if (true == _value) {
            require(permittedTokensToId[_address] == 0, ERROR_COIN_REGISTERED);
            permittedTokensToId[_address] = permittedCoinsAddresses_.length;
            permittedCoinsAddresses_.push(_address);
        }
        if (false == _value) {
            uint256 coinIndex = permittedTokensToId[_address];
            require(coinIndex != 0, ERROR_NO_CONTRACT);
            uint256 lastCoinIndex = permittedCoinsAddresses_.length.sub(1);
            permittedCoinsAddresses_[coinIndex] = permittedCoinsAddresses_[
            lastCoinIndex
            ];
            permittedTokensToId[permittedCoinsAddresses_[coinIndex]] = coinIndex;
            delete permittedCoinsAddresses_[lastCoinIndex];
            permittedTokensToId[_address] = 0;
            permittedCoinsAddresses_.length = permittedCoinsAddresses_.length.sub(1);
        }
    }

    function hasPermission(
        address _subject,
        uint256 _permissionBit
    )
    internal
    view
    returns (bool)
    {
        return permissions(_subject, _permissionBit);
    }
}

