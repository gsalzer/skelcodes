pragma solidity ^0.5.0;



import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

import './TokenLock.sol';
import './ERC20Pausable.sol';
import './Ownable.sol';

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract TradingUsdtMiningToken is  Context, ERC20, ERC20Detailed, ERC20Pausable,Ownable   {

    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    function initialize(address sender) public initializer {
        ERC20Detailed.initialize("TradingUsdtMiningToken", "TUM", 7);
        _mint(sender, 2000000000 * (10 ** uint256(decimals())));
    }

    uint256[50] private ______gap;
    
  mapping (address => uint256) public airDropHistory;
  event AirDrop(address _receiver, uint256 _amount);    
    
    
  mapping (address => address) public lockStatus;
  event Lock(address _receiver, uint256 _amount);    
  
function dropToken(address[] memory receivers, uint256[] memory values) public {
    require(receivers.length != 0);
    require(receivers.length == values.length);

    for (uint256 i = 0; i < receivers.length; i++) {
      address receiver = receivers[i];
      uint256 amount = values[i];

      transfer(receiver, amount);
      airDropHistory[receiver] += amount;

      emit AirDrop(receiver, amount);
    }
  }  
  
  function lockToken(address beneficiary, uint256 amount, uint256 releaseTime, bool isOwnable) onlyOwner public {
    TokenLock lockContract = new TokenLock(this, beneficiary, msg.sender, releaseTime, isOwnable);

    transfer(address(lockContract), amount);
    lockStatus[beneficiary] = address(lockContract);
    emit Lock(beneficiary, amount);
  }  
  
    
}
