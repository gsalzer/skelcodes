pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintDiscount is StorageV1 {
    using SafeMath for uint;

    // saving discount for user
    function _setUsersPaintDiscountForColor(uint _color) internal {

        //each 1 eth = 1% discount
        usersPaintDiscount[msg.sender] = moneySpentByUser[msg.sender] / 1 ether; // for all colors
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether; // for current color

        //max discount 10% for all colors
        if (moneySpentByUser[msg.sender] >= 10 ether) {
            usersPaintDiscount[msg.sender] = 10;
        }

        //max discount 10% for current color
        if (moneySpentByUserForColor[_color][msg.sender] >= 10 ether) {
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        }
    }

    //  Money spent by user buying this color
    function _setMoneySpentByUserForColor(uint _color) internal {

        moneySpentByUser[msg.sender] += msg.value; // for all colors
        moneySpentByUserForColor[_color][msg.sender] += msg.value; // for current color

        // for all colors
        if (moneySpentByUser[msg.sender] >= 1 ether) {
            hasPaintDiscount[msg.sender] = true;
        }

        // for current color
        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether) {
            hasPaintDiscountForColor[_color][msg.sender] = true;
        }
    }
}
