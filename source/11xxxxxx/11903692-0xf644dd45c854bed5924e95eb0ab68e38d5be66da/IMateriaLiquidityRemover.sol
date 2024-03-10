// SPDX-License-Identifier: GPL3

pragma solidity ^0.8.0;

/*
    This interface represents a break in the symmetry and should not exist since a
    Materia Operator should be able to receive only ERC1155.
    Nevertheless for the moment che Materia liquidity pool token is not wrapped
    by the orchestrator, and for this reason it cannot be sent to the Materia
    Liquidity Remover as an ERC1155 token.
    In a future realease it may introduced the LP wrap and therefore this interface
    may become useless.
*/

interface IMateriaLiquidityRemover {
    function removeLiquidity(
        address token,
        uint256 liquidity,
        uint256 tokenAmountMin,
        uint256 bridgeAmountMin,
        uint256 deadline
    ) external returns (uint256 amountBridge, uint256 amountToken);
}

