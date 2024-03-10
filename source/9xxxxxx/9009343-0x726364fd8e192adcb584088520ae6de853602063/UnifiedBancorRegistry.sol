pragma solidity ^0.5.0;

contract IBancorConverter {
    function connectorTokens(uint256 _index) public view returns (address);
}

contract IBancorConverterRegistry {
    function tokens(uint256 _index) public view returns (address);
    function tokenCount() public view returns (uint256);
    function converterCount(address _token) public view returns (uint256);
    function converterAddress(address _token, uint32 _index) public view returns (address);
    function latestConverterAddress(address _token) public view returns (address);
    function tokenAddress(address _converter) public view returns (address);
}

contract IConvertersRegistry {
    function getAllConverters() public view returns(IBancorConverter[] memory);
}

contract UnifiedBancorRegistry {

    IBancorConverterRegistry public official = IBancorConverterRegistry(0xc1933ed6a18c175A7C2058807F25e55461Cd92F5);
    IConvertersRegistry public unofficial = IConvertersRegistry(0x7bDb720aF9c0DA53744aa007984031cecA528AD0);

    function latestConverterAddress(address token) public view returns (address) {
        address converter = official.latestConverterAddress(token);
        if (converter != address(0)) {
            return converter;
        }

        IBancorConverter[] memory converters = unofficial.getAllConverters();

        for (uint i = 0; i < converters.length; i++) {
            if (converters[i].connectorTokens(1) == token) {
                return address(converters[i]);
            }
        }

        for (uint i = 0; i < converters.length; i++) {
            if (converters[i].connectorTokens(0) == token) {
                return address(converters[i]);
            }
        }

        return address(0);
    }
}
