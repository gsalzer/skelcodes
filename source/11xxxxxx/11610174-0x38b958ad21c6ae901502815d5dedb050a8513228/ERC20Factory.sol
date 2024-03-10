// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IERC20Lib.sol";

contract ERC20Factory {
  address payable public owner;

  uint256 constant serviceFee = 50000000000000000; // 0.05 ETH

  event ERC20Created(address newERC20Address);

  constructor(address payable _owner) {
    owner = _owner;
  }

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target)<<32;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602980600a3d3981f3363d3d373d3d3d363d6f000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x24), 0x5af43d82803e903d91602757fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x33)
    }
  }
  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target)<<32;
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d6f00000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1a), 0x5af43d82803e903d91602757fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x29)

      result := and(
        eq(mload(clone), mload(other)), 
        eq(mload(add(clone, 0x20)), mload(add(other, 0x20)))
      )
    }
  }

  function payout() external {
    require(owner.send(address(this).balance));
  }

  function payoutToken(address _tokenAddress) external {
    IERC20Lib token = IERC20Lib(_tokenAddress);
    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "Nothing to payout");
    token.transfer(owner, amount);
  }

  function createERC20(address libraryAddress_, string memory name_, string memory symbol_, uint256 totalSupply_) payable external {
    require(msg.value >= serviceFee, "Service Fee of 0.05ETH wasn't paid");
    address clone = createClone(libraryAddress_);
    IERC20Lib(clone).init(msg.sender, name_, symbol_, totalSupply_);
    emit ERC20Created(clone);
  }
}
