pragma solidity ^0.5.2;
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";


contract Transmute is ERC20, Ownable, ERC20Detailed("TransmuteCoin", "TRNSC", 2) {
    
  constructor(uint _totalSupply, uint _tokenSalePercentage, uint _rewardPercentage, uint _teamAdvPercentage,uint _strategicPnPercentage, uint _bountyAirdropPercentage) public  {
    _mint(msg.sender, _totalSupply*(10**2));
    tokenSaleValue(_tokenSalePercentage);
    rewardValue(_rewardPercentage);
    teamAdvisoryValue(_teamAdvPercentage);
    strategicPnValue(_strategicPnPercentage);
    bountyAirdropValue(_bountyAirdropPercentage);
    
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
        transfer(newOwner, balanceOf(msg.sender));
        _transferOwnership(newOwner);
  }
  
  

}


