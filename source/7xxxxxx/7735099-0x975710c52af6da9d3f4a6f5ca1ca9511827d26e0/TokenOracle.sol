pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

interface ERC20 {
    function name() external view returns (string memory);

    /**
     * @return the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @return the number of decimals of the token.
     */
    function decimals() external view returns (uint8);
}

contract TokenOracle {
    function fetch(ERC20[] calldata tokens) external view returns(
        uint8[] memory decimals,
        string[] memory symbols,
        string[] memory names
    ) {
        decimals = new uint8[](tokens.length);
        symbols = new string[](tokens.length);
        names = new string[](tokens.length);
        uint256 i = 0;
        for(i; i<tokens.length; i++) {
            decimals[i] = tokens[i].decimals();
            symbols[i] = tokens[i].symbol();
            names[i] = tokens[i].name();
        }
    }
}
