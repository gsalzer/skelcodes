pragma solidity ^0.5.10;

contract exchange { 
   function getEthToTokenOutputPrice(uint256) external returns(uint256); 
   function getEthToTokenInputPrice(uint256) external returns(uint256);
   function getTokenToEthInputPrice(uint256) external returns(uint256);
   function getTokenToEthOutputPrice(uint256) external returns(uint256);
}

contract testUniswap {
    
    uint256 public r1;
    uint256 public r2;
    uint256 public r3;
    uint256 public r4;
    
    function testExchangeRates(address exAdd, uint256 ethAmount, uint256 tokenAmount) public  {

        exchange exc = exchange(exAdd);

        r1 = exc.getEthToTokenOutputPrice(tokenAmount);
        r2 = exc.getEthToTokenInputPrice(ethAmount);
        r3 = exc.getTokenToEthInputPrice(tokenAmount);
        r4 = exc.getTokenToEthOutputPrice(ethAmount);
        
    }

}
