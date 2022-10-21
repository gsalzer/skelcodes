pragma solidity 0.4.24;
import "./StorageV1.sol";

contract Initializer is StorageV1 {

    //constructor
    function _initializer() internal {
        totalColorsNumber = 8;
        totalPixelsNumber = 49;

        isAdmin[msg.sender] = true;
        maxPaintsInPool = totalPixelsNumber;
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;

        priceLimitPaints = 100;

        for (uint i = 1; i <= totalColorsNumber; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.005 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
        }
        
    }
}

