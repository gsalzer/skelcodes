//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

uint256 constant targetSupply = 100 * 1e6 * 1e18; // 100 million tokens

contract ModelCoin is ERC20, ERC20Burnable, Ownable {
    bool private initialized = false;

    constructor() ERC20("MODELCOIN", "MODEL") {
        mint(msg.sender, targetSupply);
    }

    function mint(address _beneficiary, uint256 _amount) public onlyOwner notInitialized {
        _mint(_beneficiary, _amount);
    }

    function removeContract() public onlyOwner notInitialized {
        selfdestruct(payable(owner()));
    }

    function initialize() public onlyOwner notInitialized {
        initialized = true;
    }

    modifier notInitialized {
        require(!initialized);
        _;
    }
}

