// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface ICoinvestingDeFiCallee {
    // External functions
    function coinvestingDeFiCall(
        address sender, 
        uint amount0,
        uint amount1,
        bytes calldata data
    )
    external;
}

