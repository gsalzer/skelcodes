// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./ICoinvestingDeFiERC20.sol";

interface ICoinvestingDeFiPair is ICoinvestingDeFiERC20 {
    // Events
    event Burn(
        address indexed sender,
        uint amount0,
        uint amount1,
        address indexed to
    );

    event Mint(
        address indexed sender,
        uint amount0,
        uint amount1
    );

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event Sync(
        uint112 reserve0, 
        uint112 reserve1
    );

    // External functions
    function burn(address to) external returns (
        uint amount0,
        uint amount1
    );

    function initialize(
        address,
        address
    ) external;

    function mint(address to) external returns (uint liquidity);
    function skim(address to) external;
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    // External functions that are view
    function factory() external view returns (address);
    function getReserves() external view returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

    function kLast() external view returns (uint);    
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
    

    // External functions that are pure
    function MINIMUM_LIQUIDITY() external pure returns (uint);
}

