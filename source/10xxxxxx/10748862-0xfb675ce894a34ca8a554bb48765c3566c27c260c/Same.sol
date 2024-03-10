pragma solidity ^0.5.16;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC20.sol";

contract Same is Ownable, Pausable, ERC20 {
    constructor() ERC20("Samecoin token", "SAME", 8) public {
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function pause() public onlyOwner {
        return _pause();
    }

    function unpause() public onlyOwner {
        return _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal {
        super._beforeTokenTransfer(from, to, amount);
        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

