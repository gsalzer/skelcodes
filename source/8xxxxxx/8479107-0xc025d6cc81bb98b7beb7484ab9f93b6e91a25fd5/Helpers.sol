pragma solidity 0.4.24;
import "./Modifiers.sol";

contract Helpers is Modifiers {

    function getUsername(address _painter) external view returns(string username) {
        username = addressToUsername[_painter];
    }

    function isUsernameExists(string _username) external view returns(bool) {
        return usernameExists[_username];
    }

    // username lenght 1-16 symbols
    function createUsername(string _username) external isValidUsername(_username) {
        require(!usernameExists[_username], "This username already exists, try different one.");
        require(bytes(addressToUsername[msg.sender]).length == 0, "You have already created your username.");

        addressToUsername[msg.sender] = _username;
        usernameExists[_username] = true;

        emit UsernameCreated(msg.sender, _username);
    }

    function getPixelColor(uint _pixel) external view returns (uint) {
        return pixelToColorForRound[currentRound][_pixel];
    }

    //function adding new color to the game after minting
    function addNewColor() external onlyAdmin() {
        totalColorsNumber++; 
        currentPaintGenForColor[totalColorsNumber] = 1;
        callPriceForColor[totalColorsNumber] = 0.01 ether;
        nextCallPriceForColor[totalColorsNumber] = callPriceForColor[totalColorsNumber];
        paintGenToAmountForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = maxPaintsInPool;
        paintGenStartedForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = true;
        paintGenToEndTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber] - 1] = now;
        paintGenToStartTimeForColor[totalColorsNumber][currentPaintGenForColor[totalColorsNumber]] = now;
    }

}
