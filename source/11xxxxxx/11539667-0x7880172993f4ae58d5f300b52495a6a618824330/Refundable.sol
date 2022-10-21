pragma solidity ^0.5.0;

contract Refundable {

    modifier refundGasCost()
    {
        uint256 remainingGasStart = gasleft();

        _;

        uint256 remainingGasEnd = gasleft();
        uint256 usedGas = remainingGasStart - remainingGasEnd;
        // Add intrinsic gas and transfer gas. Need to account for gas stipend as well.
        usedGas += 21000 + 9700;
        // Possibly need to check max gasprice and usedGas here to limit possibility for abuse.
        uint gasCost = usedGas * tx.gasprice;
        // Refund gas cost
        tx.origin.transfer(gasCost);
        
    }
}






