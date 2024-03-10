pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract ColorTeam is Modifiers {

    using SafeMath for uint;

    //функция формирующая команду цвета из последних 100 участников выигравшим цветом
    function formColorTeam(uint _winnerColor) private returns (uint) {
        uint paintsCurrentRoundForColor = paintsCounterForColor[_winnerColor];
         if (paintsCurrentRoundForColor>1000)
        {
            paintsCurrentRoundForColor = 1000;
        }
        for (uint i =paintsCurrentRoundForColor; i > 0; i--) {
            uint teamMembersCounter;
            if (isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] == false) {
                
                if (paintsCurrentRoundForColor > 100) {
                    if (teamMembersCounter >= 100)   
                        break;
                }
            
                else {
                    if (teamMembersCounter >= paintsCurrentRoundForColor)
                        break;
                }
                
                cbTeam[cbIteration].push(counterToPainterForColor[_winnerColor][i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInCBT[cbIteration][counterToPainterForColor[_winnerColor][i]] = true;
            }
        }
        return cbTeam[cbIteration].length;
    }
    
    function calculateCBP(uint _winnerColor) private {

        uint length = formColorTeam(_winnerColor);
        address painter;
        uint totalPaintsForTeam; //засунуть в функцию calculateCBP

        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            totalPaintsForTeam += colorBankShare[cbIteration][_winnerColor][painter];
        }
        
        for (i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            painterToCBP[cbIteration][painter] = (colorBankShare[cbIteration][_winnerColor][painter].mul(colorBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

    function distributeCBP() external canDistributeCBP() {
        require(isCBPTransfered[cbIteration] == false, "Color Bank Prizes already transferred for this cbIteration");
        address painter;
        calculateCBP(winnerColorForRound[currentRound]);
        painterToCBP[cbIteration][winnerOfRound[currentRound]] += colorBankForRound[currentRound];
        uint length = cbTeam[cbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = cbTeam[cbIteration][i];
            if (painterToCBP[cbIteration][painter] != 0) {
                uint prize = painterToCBP[cbIteration][painter];
                painter.transfer(prize);
                emit CBPDistributed(currentRound, cbIteration, painter, prize);
            }
        }
        isCBPDistributable = false;
        isCBPTransfered[cbIteration] = true;
        currentRound = currentRound.add(1); //следующий раунд 
        cbIteration = cbIteration.add(1); //инкрементируем итерацию для банка цвета
        isGamePaused = false;
    }
    
}
