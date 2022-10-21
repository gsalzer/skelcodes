pragma solidity 0.6.12;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


// ColaToken with Governance.
contract ALMToken is ERC20Capped, Ownable {

    constructor(uint256 cap)  public 
        ERC20("AlchemintToken", "ALM")
        ERC20Capped(cap)
        Ownable() {
            _mint(msg.sender, cap);
        }
}
