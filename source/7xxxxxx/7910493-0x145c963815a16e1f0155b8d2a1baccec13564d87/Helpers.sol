pragma solidity 0.4.24;
import "./Modifiers.sol";

contract Helpers is Modifiers {

    //возвращает цвет пикселя в этом раунде (на данный момент)
    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }

    //функция добавления нового цвета в игру (после mint-инга нового цвета)
    function addNewColor() external onlyAdmin() {
        totalColorsNumber++; //TODO - Check whether this line should be put in the end or here
        currentPaintGenForColor[totalColorsNumber] = 1;
        callPriceForColor[totalColorsNumber] = 0.01 ether;
        nextCallPriceForColor[totalColorsNumber] = callPriceForColor[totalColorsNumber];
        paintGenToAmountForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = maxPaintsInPool;
        paintGenStartedForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = true;
        paintGenToEndTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber] - 1] = now;
        paintGenToStartTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = now;
    }

}
