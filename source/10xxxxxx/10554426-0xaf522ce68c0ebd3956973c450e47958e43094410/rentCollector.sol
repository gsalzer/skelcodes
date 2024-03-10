pragma solidity 0.6.6;

interface IRealityCards {

    function collectRentAllTokens() external;

}

contract rentCollector {
    IRealityCards rc1 = IRealityCards(0x148Bb64E8910422E74f79feF1A2E830BDe0BB938);
    IRealityCards rc2 = IRealityCards(0xc61ba76c37Dd5a1b9A076f8eD909f12155739DeC);
    IRealityCards rc3 = IRealityCards(0x8F52D7D78FEcAb66FF71592edCf92ea8E7bF3EEa);
    IRealityCards rc4 = IRealityCards(0xf30a16DdFDfbA014789E577bC59c6e2E89cEE0f5);
    
    function collectRentAllTokensAllMarkets() public 
    {
        rc1.collectRentAllTokens();
        rc2.collectRentAllTokens();
        rc3.collectRentAllTokens();
        rc4.collectRentAllTokens();
    }
}

