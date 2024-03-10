pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./StorageV1.sol";

contract Modifiers is StorageV1 {
    using SafeMath for uint;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender] == true, "You don't have admin rights.");
        _;
    }

    modifier isLiveGame() {
        require(isGamePaused == false, "Game is paused.");
        _;
    }

    modifier canDistributeCBP() {
        require(isCBPDistributable == true, "Cannot distribute color bank prize at the moment.");
        _;
    }

    modifier canDistributeTBP() {
        require(isTBPDistributable == true, "Cannot distribute time bank prize at the moment.");
        _;
    }

    //модификатор проверяющий длину реф. ссылки (длина должна быть в диапазоне от 4 до 8 символов)
    modifier isValidRefLink(string _str) {
        require(bytes(_str).length >= 4, "Ref link should be of length [4,8]");
        require(bytes(_str).length <= 8, "Ref link should be of length [4,8]");
        _;
    }
    
}
