// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./Ownable.sol";
import "./ERC20.sol";

contract ERC20WithFee is ERC20, Ownable {

  uint256 public basisPointsRate = 0;
  uint256 public maximumFee = 0;

  constructor (string memory name, string memory symbol) public ERC20(name, symbol) {}

  function calcFee(uint _value) internal view returns (uint) {
    uint fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
        fee = maximumFee;
    }
    return fee;
  }

  function transfer(address _to, uint _value) public override virtual returns (bool) {
    uint fee = calcFee(_value);
    uint sendAmount = _value.sub(fee);

    super.transfer(_to, sendAmount);
    if (fee > 0) {
      super.transfer(owner(), fee);
    }
  }

  function transferFrom(address _from, address _to, uint256 _value) public override virtual returns (bool) {
    require(_to != address(0), "ERC20WithFee: transfer to the zero address");
    require(_value <= balanceOf(_from), "ERC20WithFee: transfer amount exceeds balance");
    require(_value <= allowance(_from, msg.sender), "ERC20WithFee: allowance amount exceeds allowed");

    uint fee = calcFee(_value);
    uint sendAmount = _value.sub(fee);

    _transfer(_from, _to, sendAmount);
    if (fee > 0) {
        _transfer(_from, owner(), fee);
    }
    _approve(_from, msg.sender, allowance(_from, msg.sender).sub(_value, "ERC20WithFee: transfer amount exceeds allowance"));
    return true;
  }

  function setFeeParams(uint256 newBasisPoints, uint256 newMaxFee) public onlyOwner {
      basisPointsRate = newBasisPoints;
      maximumFee = newMaxFee.mul(uint256(10)**decimals());
      emit FeeParams(basisPointsRate, maximumFee);
  }

  // Called if contract ever adds fees
  event FeeParams(uint feeBasisPoints, uint maxFee);

}
