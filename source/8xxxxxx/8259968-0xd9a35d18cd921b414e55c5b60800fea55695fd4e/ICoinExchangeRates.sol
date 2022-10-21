pragma solidity ^0.5.6;


contract ICoinExchangeRates {

    /**
    * @dev Function to set CoinsPrices In USD
    * @param _coinsAddresses The array of addresses of stablecoins.
    * @param _prices The array of prices for stablecoins.
    * @return A boolean that indicates if the operation was successful.
    */
    function setCoinsPricesInUSD(
        address[] memory _coinsAddresses,
        uint256[] memory _prices
    )
    public
    returns(bool);

    /**
    * @dev Function to set backed up proportions for permitted coins
    * @param _coinsAddresses The array of addresses of stablecoins.
    * @param _percentageProportion percents proportions
    * @return A boolean that indicates if the operation was successful.
    */
    function setCoinsCoverageProportion(
        address[] memory _coinsAddresses,
        uint256[] memory _percentageProportion
    )
    public
    returns(bool);

    /**
       * @dev sets or unset permissions to make some actions
       * @param _address address stablecoin which is allowed/disalwed
       * @param _decimals adecimals value of stablecoin
       * @param _value bool sets/unsets _permission
    */
    function setPermissionsForCoins(
        address _address,
        bool _value,
        uint256 _decimals
    )
    public;

    /**
    * @dev Function to get USD amount from converting blobs
    * @param _blobsAmount the amount of blobs to be converted
    * @return A number of coins you can receive by converting blobs
    */
    function calculateUSDByBlobs(uint256 _blobsAmount)
    public
    view
    returns(uint256);

    /**
    * @dev Function to get amount of each stable coin based on proportion and price
    * which user can receive by blobs dissolveing
    * @param _usdAmount the amount to get stable coins
    * @return two arrays: stable coins and appropriate balances
    */
    function calculateCoinsAmountByUSD(
        uint256 _usdAmount
    )
    public
    view
    returns (address[] memory, uint256[] memory);

    /**
    * @dev Function to get amount of usd by converting stable coins
    * @param _stableCoinAddress stable coin address
    * @param _coinsAmount amount of coins to exchange
    * @return A usd amount you can receive by exchanging coin
    */
    function calculateUsdByCoin(
        address _stableCoinAddress,
        uint256 _coinsAmount
    )
    public
    view
    returns(uint256);

    /**
    * @dev Function to get amount of blobs by converting stable coins
    * @param _stableCoinAddress stable coin address
    * @param _coinsAmount amount of coins to exchange
    * @return A usd amount you can receive by exchanging coin
    */
    function calculateBlobsAmount(
        address _stableCoinAddress,
        uint256 _coinsAmount
    )
    public
    view
    returns (uint256);

    /**
    * @dev Function to get timestamp of last price update
    * @param _stableCoinAddress stable coin address
    * @return A timestamp of last update
    */
    function coinPriceUpdatedAt(address _stableCoinAddress)
    public
    view
    returns(uint256);

    /**
    * @dev Function to get price of stablecoin
    * @param _stableCoinAddress stable coin address
    * @return A price in usd
    */
    function getCoinPrice(address _stableCoinAddress)
    public
    view
    returns(uint256);

    /**
    * @dev Function to return permitted coins List
    * @return An array of coins addresses
    */
    function permittedCoinsAddresses()
    public
    view
    returns (address[] memory);

    /**
    * @dev Function to get price of blob coin
    * @return A price in usd
    */
    function blobCoinPrice()
    public
    view
    returns (uint256);

    /**
    * @dev Function to set price in usd for exact stable coin
    * @param _stableCoinAddress stable coin address
    * @param _price coin price in usd
    */
    function setCoinPrice(address _stableCoinAddress, uint256 _price) internal;

}

