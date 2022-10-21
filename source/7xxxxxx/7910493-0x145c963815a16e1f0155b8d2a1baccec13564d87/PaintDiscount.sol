pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract PaintDiscount is StorageV1 {
    using SafeMath for uint;
    
    //функция сохраняющая скидку на покупку краски определенного цвета для пользователя
    function _setUsersPaintDiscountForColor(uint _color) internal {
        
        //за каждый потраченный 1 ETH даем скидку 1%
        usersPaintDiscountForColor[_color][msg.sender] = moneySpentByUserForColor[_color][msg.sender] / 1 ether;
        
        //максимальная скидка может равняться 10%
        if (moneySpentByUserForColor[_color][msg.sender] >= 10 ether)
            usersPaintDiscountForColor[_color][msg.sender] = 10;
        
    }
    
    //функция сохраняющая общюю сумму потраченную пользователем на покупку краски определенного цвета за все время
    function _setMoneySpentByUserForColor(uint _color) internal {
        
        moneySpentByUserForColor[_color][msg.sender] += msg.value;
        moneySpentByUser[msg.sender] += msg.value;

        if (moneySpentByUserForColor[_color][msg.sender] >= 1 ether)
            hasPaintDiscountForColor[_color][msg.sender] = true;
    }
}
