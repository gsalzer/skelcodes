// File: contracts/interfaces/IUniswapV2Pair.sol

pragma solidity ^0.5.0;

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function token0() external view returns (address);
    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
}

// File: contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.5.0;



interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (IUniswapV2Pair pair);
    function allPairsLength() external view returns (uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// File: contracts/UniswapV2Helper.sol

pragma solidity ^0.5.12;




contract UniswapV2Helper {

    IUniswapV2Factory constant factory =  IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    function getPairsByReserveToken(address reserveToken) external view returns (address[] memory pairs) {

        uint256 pairsCount = factory.allPairsLength();
        address[] memory allPairs = new address[](pairsCount);

        uint256 notEmptyLength;
        for (uint i; i < pairsCount; i++) {
            IUniswapV2Pair pair = factory.allPairs(i);
            if (
                reserveToken == pair.token0() ||
                reserveToken == pair.token1()
            ) {
                allPairs[notEmptyLength] = address(pair);
                notEmptyLength++;
            }
        }

        pairs = new address[](notEmptyLength);
        for (uint i; i < notEmptyLength; i++) {
            pairs[i] = allPairs[i];
        }
    }

}
