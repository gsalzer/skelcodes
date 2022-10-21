pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";

contract LuckyPot is Modifiers {
    using SafeMath for uint;

    function increaseLuckyPot() external payable {
        require(msg.value != 0, "msg.value is 0");
        luckyPotBank = luckyPotBank.add(msg.value);
    }

    function drawLuckyPot(address _user, uint _bankPercent, uint _pixelId) external onlyAdmin() {
        require(luckyPotBank > 0, "luckyPotBank is empty");
        require(_bankPercent > 0 && _bankPercent <= 100, "Invalid percent");
        require(_pixelId > 0 && _pixelId <= totalPixelsNumber, "The pixel with such id does not exist.");

        uint luckyPotBankAmountForWinner = luckyPotBank.mul(_bankPercent).div(100);

        // change luckyPotBank state
        luckyPotBank = luckyPotBank.sub(luckyPotBankAmountForWinner);
        luckyPotBankWinner[_user] = true;

        // transfer luckypot
        _user.transfer(luckyPotBankAmountForWinner);
        emit LuckyPotDrawn(_pixelId, _user, luckyPotBankAmountForWinner);
    }
}
