// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Extractable is Ownable {
  function withdraw() external payable onlyOwner {
    require(payable(owner()).send(address(this).balance), "!transfer");
  }

  function extract(address _token) external onlyOwner {
    IERC20 token = IERC20(_token);
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}

