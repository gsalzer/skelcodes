pragma solidity ^0.5.10;


contract exchange { 
   function getEthToTokenOutputPrice(uint256) external returns(uint256); 
   function getEthToTokenInputPrice(uint256) external returns(uint256);
}

contract testUniswap {
    
    // Rinkeby
    // address a = 0x77dB9C915809e7BE439D2AB21032B1b8B58F6891;
    // Mainnet
    address a = 0x09cabEC1eAd1c0Ba254B09efb3EE13841712bE14;
    exchange exc = exchange(a);

    /*
    Rinkeby
    DAI
    Token: 0x2448eE2641d78CC42D7AD76498917359D961A783
    Exchange: 0x77dB9C915809e7BE439D2AB21032B1b8B58F6891
    Initial Liquidity: 20k DAI, 50 ETH
    */

    uint256 public eth_sold1 = 10;
    uint256 public tokens_bought1 = 1000;
    uint256 public exchRate1 = 0;
    
    uint256 public eth_sold2 = 10;
    uint256 public tokens_bought2 = 10;
    uint256 public exchRate2 = 0;
    
    function test1() public returns (uint256,uint256,uint256,uint256,uint256,uint256) {

        // ERC20 --> ETH
        eth_sold1 = exc.getEthToTokenOutputPrice(tokens_bought1); // uint256
        
        exchRate1 = tokens_bought1 / eth_sold1;
        //0.076 = 1000/76

        // ETH --> ERC20
        tokens_bought2 = exc.getEthToTokenInputPrice(eth_sold2); // uint256
        
        exchRate2 = eth_sold2 / tokens_bought2;
        //0.07518796992 = 10 / 133
        
        return(exchRate1, eth_sold1, tokens_bought1, exchRate2, eth_sold2, tokens_bought2);
    }

}
