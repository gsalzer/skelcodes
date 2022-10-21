pragma solidity ^0.5.8;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract Vault is Ownable {
  using SafeMath for uint;

  address public investor;
  IERC20 internal bfclToken;

  constructor(address _investor, IERC20 _bfclToken) public {
    investor = _investor;
    bfclToken = _bfclToken;
  }

  // reverts erc223 transfers
  function tokenFallback(address, uint, bytes calldata) external pure {
    revert("ERC223 tokens not allowed in Vault");
  }

  function withdrawToInvestor(uint _amount) external onlyOwner returns (bool) {
    bfclToken.transfer(investor, _amount);
    return true;
  }

  function getBalance() public view returns (uint) {
    return bfclToken.balanceOf(address(this));
  }
}

