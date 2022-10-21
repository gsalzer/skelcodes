// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/proxy/Initializable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import '../adapters/CompoundAdapter.sol';
import '../interfaces/IAdapter.sol';
import '../interfaces/INutmeg.sol';

contract MockAdapter is CompoundAdapter {
  using SafeERC20 for IERC20;
  using SafeMath for uint;

  event Received(address, uint);
  address public immutable weth;

  constructor(INutmeg nutmegAddr, address wethAddr) CompoundAdapter(nutmegAddr) {
    weth = wethAddr;
  }

  function test() external pure {
  }

  function testFail() external pure {
    require(false, "fail");
  }

  function testBorrow(uint amount) external {
    INutmeg(nutmeg).borrow(weth, address(this), amount-10, amount);
  }

  function testCurrPositionId(uint pos) external view {
    uint posret = INutmeg(nutmeg).getCurrPositionId();
    require(pos == posret, 'testCurrentPosition failed');
  }

  function testPosition(uint pos) external view {
    INutmeg.Position memory p = INutmeg(nutmeg).getPosition(pos);
    require(p.id == pos, 'testPosition failed');
  }

  function testRepay(address token, uint repayAmount) external {
    INutmeg(nutmeg).repay(token, repayAmount);
  }

  receive() external payable {
     emit Received(msg.sender, msg.value);
  }
}

/* Local Variables:   */
/* mode: javascript   */
/* js-indent-level: 2 */
/* End:               */

