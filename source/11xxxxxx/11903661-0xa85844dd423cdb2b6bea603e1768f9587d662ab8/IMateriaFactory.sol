// SPDX-License-Identifier: GPL3

interface IMateriaFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setDefaultMateriaFee(uint256) external;

    function setDefaultSwapFee(uint256) external;

    function transferOwnership(address newOwner) external;

    function setFees(
        address,
        uint256,
        uint256
    ) external;

    function owner() external view returns (address);
}

