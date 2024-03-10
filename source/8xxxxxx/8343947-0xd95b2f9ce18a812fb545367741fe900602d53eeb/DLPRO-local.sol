// contracts/CustomERC20.sol
pragma solidity ^0.5.2;

import "./Initializable.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./ERC20Pausable.sol";
import "./ERC20Mintable.sol";

contract DLPRO is Initializable, ERC20, ERC20Detailed, ERC20Burnable, ERC20Pausable, ERC20Mintable {

  function initialize( string memory name, string memory symbol, uint8 decimals, uint256 initialSupply, address initialHolder )
   public initializer {
    require(initialSupply > 0, "");
    ERC20Detailed.initialize(name, symbol, decimals);
    ERC20Mintable.initialize(msg.sender);
    ERC20Pausable.initialize(msg.sender);
    _mint(initialHolder, initialSupply);
  }
}
