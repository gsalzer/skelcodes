// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@amxx/hre/contracts/ENSReverseRegistration.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "./extensions/IMintable.sol";

contract Gang is
    IMintable,
    AccessControlUpgradeable,
    ERC20VotesUpgradeable,
    MulticallUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(string memory name, string memory symbol)
    public
        initializer()
    {
        __AccessControl_init();
        __ERC20_init(name, symbol);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function mint(address to, uint256 value)
    public
        onlyRole(MINTER_ROLE)
    {
        _mint(to, value);
    }

    function setName(address ensRegistry, string calldata ensName)
    external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }
}
