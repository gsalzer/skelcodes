pragma solidity ^0.4.24;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./KaikenInuToken.sol";


contract TokenBonus is Ownable {
    using SafeMath for uint256;

    address public owner;
    mapping (address => uint256) public bonusBalances;   // visible to the public or not ???
    address[] public bonusList;
    uint256 public savedBonusToken;

    constructor() public {
        owner = msg.sender;
    }

    function distributeBonusToken(address _token, uint256 _percent) public onlyOwner {
        for (uint256 i = 0; i < bonusList.length; i++) {
            require(KaikenInuToken(_token).balanceOf(address(this)) >= savedBonusToken);

            uint256 amountToTransfer = bonusBalances[bonusList[i]].mul(_percent).div(100);
            KaikenInuToken(_token).transfer(bonusList[i], amountToTransfer);
            bonusBalances[bonusList[i]] = bonusBalances[bonusList[i]].sub(amountToTransfer);
            savedBonusToken = savedBonusToken.sub(amountToTransfer);
        }
    }
}

