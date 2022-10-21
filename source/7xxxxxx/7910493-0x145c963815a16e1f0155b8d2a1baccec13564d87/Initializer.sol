pragma solidity 0.4.24;
import "./StorageV1.sol";

contract Initializer is StorageV1 {

    //constructor
    function _initializer() internal {

        
        refLinkPrice  = 0.1 ether;
        totalColorsNumber = 8;
        totalPixelsNumber = 49;
        
        isAdmin[msg.sender] = true;
        maxPaintsInPool = totalPixelsNumber; 
        currentRound = 1;
        cbIteration = 1;
        tbIteration = 1;
        
        for (uint i = 1; i <= totalColorsNumber; i++) {
            currentPaintGenForColor[i] = 1;
            callPriceForColor[i] = 0.005 ether;
            nextCallPriceForColor[i] = callPriceForColor[i];
            paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
            paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
            //paintGenToEndTimeForColor[i][currentPaintGenForColor[i] - 1] = now;
            paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
        }
        
    }
}

