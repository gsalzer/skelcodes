pragma solidity 0.4.24;
import "./Roles.sol";
import "./Modifiers.sol";

contract GameStateController is Modifiers {

    function pauseGame() external onlyAdmin() {
        require (isGamePaused == false, "Game is already paused");
        isGamePaused = true;
    }

    function resumeGame() external onlyAdmin() {
        require (isGamePaused == true, "Game is already live");
        isGamePaused = false;
    }

    function withdrawEther() external onlyAdmin() returns (bool) {
        require (isGamePaused == true, "Can withdraw when game is live");
        uint balance = address(this).balance;
        uint colorBank = colorBankForRound[currentRound];
        uint timeBank = timeBankForRound[currentRound];
        owner().transfer(balance);
        colorBankForRound[currentRound]= 0;
        timeBankForRound[currentRound]= 0;
        emit EtherWithdrawn(balance, colorBank, timeBank, now);
        return true;
    }
    
}

