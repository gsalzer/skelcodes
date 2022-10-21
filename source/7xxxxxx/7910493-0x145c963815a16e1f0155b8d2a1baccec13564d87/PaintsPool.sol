pragma solidity ^0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintsPool is StorageV1 {
    using SafeMath for uint;

    //функция обновления цены вызова функции закрашивания (paint)
    function _updateCallPrice(uint _color) private {
        
        //увеличиваем цену вызова на 5% (используем для отображения на фронте)
        nextCallPriceForColor[_color] = callPriceForColor[_color].mul(105).div(100);
        
        //вызываем ивент о том, что цена вызова функции paint обновлена
        emit CallPriceUpdated(callPriceForColor[_color]);
    

    }
    //функция пополнения пула краски
    function _fillPaintsPool(uint _color) internal {

        //следующее поколение краски
        uint nextPaintGen = currentPaintGenForColor[_color].add(1);
        //каждые полторы минуты пул дополняется новой краской
        if (now - paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color] - 1] >= 1.5 minutes) { 
            
            //сколько краски остается в поколении
            uint paintsRemain = paintGenToAmountForColor[_color][currentPaintGenForColor[_color]]; 
            
            //если прошло полторы минуты и след. поколение краски все еще не создано     
            if (paintGenStartedForColor[_color][nextPaintGen] == false) {
                
                //создаем новое поколение краски на недостающее количество единиц
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool.sub(paintsRemain); 
                
                //новое поколение создалось сейчас
                paintGenToStartTimeForColor[_color][nextPaintGen] = now; 

                paintGenStartedForColor[_color][nextPaintGen] = true;
            }
            
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 1) {
                
                //обновляем цену вызова закрашивания краской следующего поколения
                _updateCallPrice(_color);
                
                //краска текущего поколения закончилась сейчас
                paintGenToEndTimeForColor[_color][currentPaintGenForColor[_color]] = now;
            }
               
            //как только не осталось краски текущего поколения
            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
                
                //цена вызова закрашивания краской текущего поколения
                callPriceForColor[_color] = nextCallPriceForColor[_color];

                if (paintGenToAmountForColor[_color][nextPaintGen] == 0) {
                    paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                }
                //переходим на использование следующего поколения краски
                currentPaintGenForColor[_color] = nextPaintGen;
            }
        }
        ///если не прошло полторы минуты
        else {

            if (paintGenToAmountForColor[_color][currentPaintGenForColor[_color]] == 0) {
               
                paintGenToAmountForColor[_color][nextPaintGen] = maxPaintsInPool;
                //переходим на использование следующего поколения краски
                currentPaintGenForColor[_color] = nextPaintGen;
            }

        }
    }
}
