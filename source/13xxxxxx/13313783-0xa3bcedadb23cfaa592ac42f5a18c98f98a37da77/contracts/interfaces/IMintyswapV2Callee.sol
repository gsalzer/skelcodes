pragma solidity >=0.5.0;

interface IMintyswapV2Callee {
    function MintyswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

