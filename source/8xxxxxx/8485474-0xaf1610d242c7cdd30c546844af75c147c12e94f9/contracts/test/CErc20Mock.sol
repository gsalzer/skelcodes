/**
Copyright 2019 PoolTogether LLC

This file is part of PoolTogether.

PoolTogether is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation under version 3 of the License.

PoolTogether is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with PoolTogether.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.5.10;

import "../compound/ICErc20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

contract CErc20Mock is Initializable, ICErc20 {
  mapping(address => uint256) ownerTokenAmounts;

  uint __supplyRatePerBlock;

  function initialize (address _token, uint256 _supplyRatePerBlock) public initializer {
    require(_token != address(0), "token is not defined");
    underlying = _token;
    __supplyRatePerBlock = _supplyRatePerBlock;
  }

  function mint(uint amount) external returns (uint) {
    ownerTokenAmounts[msg.sender] = ownerTokenAmounts[msg.sender] + amount;
    require(IERC20(underlying).transferFrom(msg.sender, address(this), amount), "could not transfer tokens");
    return 0;
  }

  function getCash() external view returns (uint) {
    return IERC20(underlying).balanceOf(address(this));
  }

  function redeemUnderlying(uint requestedAmount) external returns (uint) {
    require(ownerTokenAmounts[msg.sender] > 0, "you must have supplied tokens");
    ownerTokenAmounts[msg.sender] = ownerTokenAmounts[msg.sender] - requestedAmount;
    require(IERC20(underlying).transfer(msg.sender, requestedAmount), "could not transfer tokens");
  }

  function reward(address account) external {
    ownerTokenAmounts[account] = (ownerTokenAmounts[account] * 120) / 100;
  }

  function balanceOfUnderlying(address account) external returns (uint) {
    return ownerTokenAmounts[account];
  }

  function supplyRatePerBlock() external view returns (uint) {
    return __supplyRatePerBlock;
  }

  function setSupplyRateMantissa(uint256 _supplyRatePerBlock) external {
    __supplyRatePerBlock = _supplyRatePerBlock;
  }
}

