pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintsPool is StorageV1 {
    using SafeMath for uint;

    //update paint price
    function _updateCallPrice(uint _color) private {
        
        //increase call price for 5%(for frontend)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        
        emit CallPriceUpdated(callPriceForColor[_color]);
    }
     
    
    
    function _fillPaintsPool(uint _color) internal {

        
        uint nextPaintGen = currentPaintGenForColor[_color].add(1);
        //each 5 min we produce new paint generation
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 5 minutes) { 
            
            
            uint paintsRemain = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]]; 
            
            //if 5 min passed and new gen not yet started     
            if (paintGenStartedForColor[_color][nextPaintGen] == false) {
                
                //we create new gen with amount of paints remaining 
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                
                paintGenToStartTimeForColor[_color][nextPaintGen] = now; 

                paintGenStartedForColor[_color][nextPaintGen] = true;
            }
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 1) {
                
                
                _updateCallPrice(_color);
                
                //current gen paiints ends now 
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;
            }
               
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
               
                callPriceForColor[_color] = nextCallPriceForColor[_color];

                if (paintGenToAmountForColor[_color][nextPaintGen] == 0) {
                    paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                }
                //now we use next gen paints
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
        ///if 5 min not yet passed
        else {

            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
               
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                //we use next paint gen
                currentPaintGenForColor[_color] = nextPaintGen;
            }

        }
    }
}
