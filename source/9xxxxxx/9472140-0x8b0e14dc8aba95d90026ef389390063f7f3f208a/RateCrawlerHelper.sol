pragma solidity 0.6.1;

// Solidity Interface

interface UniswapExchangeInterface {
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold) external view returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought) external view returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought) external view returns (uint256 tokens_sold);
}

contract RateCrawlerHelper {

    function getTokenRates(UniswapExchangeInterface uniswapExchangeContract, uint[] memory amounts)
        public view
        returns(uint[] memory inputPrices, uint[] memory outputPrices)
    {
        inputPrices = new uint[](amounts.length);
        outputPrices = new uint[](amounts.length);

        for ( uint i = 0; i < amounts.length; i++ ) {
            inputPrices[i] = uniswapExchangeContract.getEthToTokenInputPrice(amounts[i]);
            outputPrices[i] = uniswapExchangeContract.getTokenToEthOutputPrice(amounts[i]);
        }
    }
}
