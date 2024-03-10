pragma solidity 0.4.24;
import "./SafeMath.sol";
import "./Modifiers.sol";
import "./Utils.sol";

contract Referral is Modifiers {
    using SafeMath for uint;
    
    //функция для покупки реферальной ссылки для пользователя (длина в диапазоне от 4 до 8 символов)
    function buyRefLink(string _refLink) isValidRefLink (_refLink) external payable {
        require(msg.value == refLinkPrice, "Setting referral link costs 0.1 ETH.");
        require(hasRefLink[msg.sender] == false, "You have already generated your ref link.");
        bytes32 refLink32 = Utils.toBytes16(_refLink);
        require(refLinkExists[refLink32] != true, "This referral link already exists, try different one.");
        hasRefLink[msg.sender] = true;
        userToRefLink[msg.sender] = _refLink;
        refLinkExists[refLink32] = true;
        refLinkToUser[refLink32] = msg.sender;
        owner().transfer(msg.value);
    }

    //функция возвращающая список реферралов для пользователя _user
    function getReferralsForUser(address _user) external view returns (address[]) {
        return referrerToReferrals[_user];
    }

    function getReferralData(address _user) external view returns (uint registrationTime, uint moneySpent) {
        registrationTime = registrationTimeForUser[_user];
        moneySpent = moneySpentByUser[_user];
    }
    
}
