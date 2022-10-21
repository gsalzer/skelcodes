pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AVGERC20 is Ownable, ERC20 {
    constructor(string memory name_, string memory symbol_)
        Ownable()
        ERC20(name_, symbol_)
    {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

