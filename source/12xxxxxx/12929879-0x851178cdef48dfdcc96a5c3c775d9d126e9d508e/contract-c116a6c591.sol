// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable@4.2.0/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.2.0/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.2.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@4.2.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable@4.2.0/proxy/utils/UUPSUpgradeable.sol";

contract Remocoin is Initializable, ERC20Upgradeable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    function initialize() initializer public {
        __ERC20_init("Remocoin", "REMO");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}

