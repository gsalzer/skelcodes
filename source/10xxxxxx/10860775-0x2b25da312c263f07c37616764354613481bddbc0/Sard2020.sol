pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";

contract SARD2020 is ERC20, ERC20Detailed, Ownable {
    constructor()
        public
        ERC20()
        ERC20Detailed("SardToken2020", "SRD20", 0)
        // Owner account
        Ownable(msg.sender) // /!\ Owner address /!\
    {
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function burnFromOwner(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
        emit Approval(account, owner(), amount);
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);
        return true;
    }

    function mintBatch(address[] memory accounts, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(accounts.length == amounts.length, "Invalid batch size");
        for (uint index = 0; index < accounts.length; index++) {
            mint(accounts[index], amounts[index]);
        }
    }

}

