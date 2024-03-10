// SPDX-License-Identifier: MIT

/******************************************************************************\
* (https://github.com/shroomtopia)
* Implementation of ShroomTopia's ERC20 SPOR Token
/******************************************************************************/

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ISPORToken} from "../../Shared/interfaces/ISPORToken.sol";

contract SPORTokenMainnet is Context, ISPORToken, Initializable {
  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint256 private _cap;

  address private mainnetERC20Predicate;
  address private shroomTopiaDao;

  function initToken(
    uint256 cap_,
    uint256 initialsupply_,
    address team_,
    address mainnetERC20Predicate_,
    address shroomTopiaDao_
  ) external initializer {
    _mint(team_, initialsupply_);
    mainnetERC20Predicate = mainnetERC20Predicate_;
    shroomTopiaDao = shroomTopiaDao_;
    _cap = cap_;
  }

  // Only ShroomTopia DAO can call this!
  function capChange(uint256 cap_) external {
    require(msg.sender == shroomTopiaDao, "ERC20: Not Authorized");
    _cap = cap_;
  }

  function cap() public view virtual returns (uint256) {
    return _cap;
  }

  // Only ShroomTopia DAO can call this!
  function mint(address user, uint256 amount) external override {
    require(msg.sender == shroomTopiaDao || msg.sender == mainnetERC20Predicate, "ERC20: Not Authorized");

    require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
    _mint(user, amount);
  }

  function name() public view virtual override returns (string memory) {
    return "ShroomTopia SPOR Token";
  }

  function symbol() public view virtual override returns (string memory) {
    return "SPOR";
  }

  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);

    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), "ERC20: mint to the zero address");

    _totalSupply += amount;
    _balances[account] += amount;
    emit Transfer(address(0), account, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

