// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SafariErc20 is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  address public stripesAddress;
  bool public stripesBurning;
  
  function initialize(string memory name, string memory symbol, address stripes) public initializer {
    __ERC20_init(name, symbol);
    __Ownable_init();
    stripesAddress = stripes;
    stripesBurning = false;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  function burnStripes(uint256 amount) external {
    require(stripesBurning, 'burning stripes is not currently allowed');

    IERC20(stripesAddress).transferFrom(_msgSender(), address(this), amount);
    _mint(_msgSender(), amount);
  }

  function setStripesBurning(bool val) external onlyOwner {
    stripesBurning = val;
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}

