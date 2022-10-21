/**
 *Submitted for verification at Etherscan.io on 2020-11-10
*/

pragma solidity ^0.6.0;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
        return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
}

contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() internal {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Vesting is Ownable {

  using SafeMath for uint;

  address public beneficiary;
  IERC20 public asset;

  uint public startTime;
  uint public duration;
  uint public released;
  bool public revoked;

  constructor(
    address _beneficiary,
    IERC20 _asset,
    uint _startTime,
    uint _duration
  ) public {

    require(_beneficiary != address(0), "Vesting: _beneficiary is zero address");
    require(_asset != IERC20(0), "Vesting: _asset is zero address");
    require(_startTime.add(_duration) > block.timestamp, "Vesting: final time is before current time");
    require(_duration > 0, "Vesting: _duration == 0");

    beneficiary = _beneficiary;
    asset = _asset;
    startTime = _startTime;
    duration = _duration;
  }

  function release(uint _amount) external {
    require(msg.sender == beneficiary, "Vesting: not beneficiary");
    uint unreleased = releasableAmount();

    require(unreleased > 0, "Vesting: no assets are due");
    require(unreleased > _amount, "Vesting: _amount too high");

    released = released.add(_amount);
    asset.transfer(beneficiary, _amount);
  }

  function revoke() external onlyOwner {
    require(!revoked, "Vesting: asset already revoked");

    uint balance = asset.balanceOf(address(this));

    uint unreleased = releasableAmount();
    uint refund = balance.sub(unreleased);

    revoked = true;

    asset.transfer(owner, refund);
    asset.transfer(beneficiary, unreleased);
  }

  function releasableAmount() public view returns (uint) {
    return vestedAmount().sub(released);
  }

  function vestedAmount() public view returns (uint) {
    uint currentBalance = asset.balanceOf(address(this));
    uint totalBalance = currentBalance.add(released);

    if (block.timestamp >= startTime.add(duration)) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(startTime)).div(duration);
    }
  }
}
