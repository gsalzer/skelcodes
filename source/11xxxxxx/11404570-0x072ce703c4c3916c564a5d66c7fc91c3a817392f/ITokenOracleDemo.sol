pragma solidity ^0.6.6;

interface ITokenOracleDemo {

    event UpdatePairCount(uint32 blockTimestamp, uint oldLength, uint newLength, uint count);
    event UpdatePairPriceLatest(address indexed pair, uint token0Price, uint token1Price, uint32 blockTimestamp);

    function decimals() external view returns (uint8);

    function getPairInfoLength() external view returns (uint);
    function updatePairs() external;
    function updatePairPriceAll() external;
    function updatePairPriceSingle(address pair) external returns (bool);
    function getPairToken(uint index) external view returns (address pair, address token0, address token1);
    function getPairTokenDecimals(uint index) external view returns (uint8 token0Decimals, uint8 token1Decimals);
    function getPairTokenPriceCumulativeLast(uint index) external view returns (uint price0CumulativeLast, uint price1CumulativeLast);
    function getPairPrice(address token0, address token1) external view returns (uint);
    function getPairPriceByIndex(uint index) external view returns (address pair, string memory token0Symbol, string memory token1Symbol, uint token0Price, uint token1Price, uint blockTimestamp);
    function getPairPriceBySymbol(string calldata token0, string calldata token1) external view returns (address pair, uint token0Price, uint token1Price, uint blockTimestamp);
    function getPairPriceByAddress(address pair) external view returns (string memory token0Symbol, string memory token1Symbol, uint token0Price, uint token1Price, uint blockTimestamp);
    function getPairUpdatePriceTime(address token0, address token1) external view returns (uint);

    function getTokenLength() external view returns (uint);
    function getTokenPriceUSD(address) external view returns (uint);
    function getTokenPriceByIndex(uint index) external view returns (address token, string memory symbol, uint price, uint blockTimestamp);
    function getTokenPriceByAddress(address token) external view returns (string memory symbol, uint price, uint blockTimestamp);
    function getTokenPriceBySymbol(string calldata symbol) external view returns (address token, uint price, uint blockTimestamp);    
    function getTokenPriceUpdateTime(address) external view returns (uint);

}

