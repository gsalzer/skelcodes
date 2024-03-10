pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YouBetToken is ERC20("You Bet!", "UBET"), Ownable {

  bool private mintable = true;

  mapping (address => uint16) public pools;

  function setPool (address _pool) onlyOwner external {
    pools[_pool] = 1;
  }

  function mint (address account, uint256 amount) onlyOwner external {

    require (mintable, "already initialized");
    
    _mint(account, amount);
    mintable = false;
    
  }

  function burn (address account, uint256 amount) onlyOwner external {
    _burn(account, amount);
  }
  
  function burnFromPool (uint256 amount) external {
    require (pools[msg.sender] == 1, "Forbidden");
    _burn(msg.sender, amount);
  }
  
}
