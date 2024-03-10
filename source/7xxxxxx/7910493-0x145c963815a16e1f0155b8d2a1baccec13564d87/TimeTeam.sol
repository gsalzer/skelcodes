pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract TimeTeam is Modifiers {
    using SafeMath for uint;

    //функция формирующая команду времени из последних 100 участников любым цветом
    function formTimeTeam() private returns (uint) {
    uint paintsCurrentRound = paintsCounter; 
  	  if (paintsCurrentRound>1000)
        {
            paintsCurrentRound = 1000;
        }
        
        for (uint i = paintsCurrentRound; i > 0; i--) {
            uint teamMembersCounter;
            if (isInTBT[tbIteration][counterToPainter[i]] == false) {
                
                  if (teamMembersCounter >= paintsCurrentRound)
                        break;
              
                else {
                    if (teamMembersCounter >= 50)   
                        break;
                }
                
                
                tbTeam[tbIteration].push(counterToPainter[i]);
                teamMembersCounter = teamMembersCounter.add(1);
                isInTBT[tbIteration][counterToPainter[i]] = true;
            }
        }
        return tbTeam[tbIteration].length;
    }
    
    function calculateTBP() private {

        uint length = formTimeTeam();
        address painter;
        uint totalPaintsForTeam; 

        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            totalPaintsForTeam += timeBankShare[tbIteration][painter];
        }

        for (i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            painterToTBP[tbIteration][painter] = (timeBankShare[tbIteration][painter].mul(timeBankForRound[currentRound])).div(totalPaintsForTeam);
        }

    }

   function resetPaintsPool() internal {
        
    
    for (uint i = 1; i<totalColorsNumber;i++){
      
        callPriceForColor[i] = 0.005 ether;
        nextCallPriceForColor[i] = callPriceForColor[i];
        currentPaintGenForColor[i]= 1;
        
        paintGenToAmountForColor[i][currentPaintGenForColor[i]] = maxPaintsInPool;
        paintGenStartedForColor[i][currentPaintGenForColor[i]] = true;
        paintGenToStartTimeForColor[i][currentPaintGenForColor[i]] = now;
    }
    
    }

    function distributeTBP() external canDistributeTBP() {
        require(isTBPTransfered[tbIteration] == false, "Time Bank Prizes already transferred for this tbIteration");
        address painter;
        calculateTBP();
        painterToTBP[tbIteration][winnerOfRound[currentRound]] += timeBankForRound[currentRound];
        uint length = tbTeam[tbIteration].length;
        for (uint i = 0; i < length; i++) {
            painter = tbTeam[tbIteration][i];
            if (painterToTBP[tbIteration][painter] != 0) {
                uint prize = painterToTBP[tbIteration][painter];
                painter.transfer(prize);
                emit TBPDistributed(currentRound, tbIteration, painter, prize);
            }
        }
        isTBPDistributable = false;
        isTBPTransfered[tbIteration] = true;
        resetPaintsPool();
        currentRound = currentRound.add(1); //следующий раунд 
        tbIteration = tbIteration.add(1); //инкрементируем итерацию для банка цвета
        isGamePaused = false;
    }
}
