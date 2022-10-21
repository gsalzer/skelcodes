pragma solidity ^0.5.13;

contract XAudTokenConfig {

    string internal constant TOKEN_SYMBOL = "XAUD";
    string internal constant TOKEN_NAME = "XAUD Token";
    uint8 internal constant TOKEN_DECIMALS = 5;

    uint256 private constant DECIMALS_FACTOR = 10**uint256(TOKEN_DECIMALS);
    uint256 internal constant TOKEN_INITIALSUPPLY = 0;

    uint256 internal constant TOKEN_MINTCAPACITY = 100 * DECIMALS_FACTOR;
    uint internal constant TOKEN_MINTPERIOD = 24 hours;
    
    function makeAddressSingleton(address _addr)
        internal
        pure
        returns (address[] memory addrs)
    {
        addrs = new address[](1);
        addrs[0] = _addr;
    }
    
}

