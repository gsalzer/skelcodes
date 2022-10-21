pragma solidity ^0.4.26;

interface OrFeedInterface {
    function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
    function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
    function getTokenAddress ( string symbol ) external view returns ( address );
    function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
    function getForexAddress ( string symbol ) external view returns ( address );
}

contract ArbitrageTest {
    uint256 internal constant _ETH_UNIT = 1000000000000000000;

    OrFeedInterface internal _orfeed;

    address private _owner;

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    //
    // Initialize
    //
    constructor() public {
        _owner = msg.sender;
        _orfeed = OrFeedInterface(0x3c1935Ebe06Ca18964A5B49B8Cd55A4A71081DE2);
    }

    function () external payable  {}

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }




    function getKyberBuyEthPrice() public view returns (uint256){
        uint256 currentPrice =  _orfeed.getExchangeRate("ETH", "SAI", "BUY-KYBER-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }
    function getKyberSellEthPrice() public view returns (uint256){
        uint256 currentPrice =  _orfeed.getExchangeRate("ETH", "SAI", "SELL-KYBER-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }

    function getUniswapBuyEthPrice() public view returns (uint256){
        uint256 currentPrice =  _orfeed.getExchangeRate("ETH", "SAI", "BUY-UNISWAP-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }
    function getUniswapSellEthPrice() public view returns (uint256){
        uint256 currentPrice =  _orfeed.getExchangeRate("ETH", "SAI", "SELL-UNISWAP-EXCHANGE", _ETH_UNIT);
        return currentPrice;
    }



    function getPrice(string from, string to, string venue, uint256 amount) public view returns (uint256) {
        uint256 currentPrice = _orfeed.getExchangeRate(from, to, venue, amount);
        return currentPrice;
    }



    function getKyberBuyPrice(string tokenSymbol) public constant returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-KYBER-EXCHANGE", 1 ether);
    }

    function getKyberSellPrice(string tokenSymbol) public constant returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-KYBER-EXCHANGE", 1 ether);
    }

    function getUniswapBuyPrice(string tokenSymbol) public constant returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "BUY-UNISWAP-EXCHANGE", 1 ether);
    }

    function getUniswapSellPrice(string tokenSymbol) public constant returns (uint256) {
        return _orfeed.getExchangeRate("ETH", tokenSymbol, "SELL-UNISWAP-EXCHANGE", 1 ether);
    }


    function setOrFeedInterface(OrFeedInterface orfeed) public onlyOwner {
        require(address(orfeed) != address(0), "Invalid OrFeedInterface address");
        _orfeed = OrFeedInterface(orfeed);
    }

}
