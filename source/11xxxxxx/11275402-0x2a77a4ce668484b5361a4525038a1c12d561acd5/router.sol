//////////////////////////////////////////////////
//SYNLEV ROUTER CONTRACT V 1.0.0
//////////////////////////

pragma solidity >= 0.6.4;

import './IERC20.sol';
import './vaultInterface.sol';

contract router {

  constructor() public { }

  modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, 'SynLevRouter: EXPIRED');
    _;
  }

  receive() external payable {}

  function buyBullTokens(
    address payable vault,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 deadline
  ) public payable ensure(deadline) {
    vaultInterface ivault = vaultInterface(vault);
    address token = ivault.getBullToken();
    ivault.updatePrice();
    uint256 price = ivault.getPrice(token);
    require(price >= minPrice && price <= maxPrice, 'SynLevRouter: TOKEN PRICE OUT OF RANGE');
    vault.transfer(address(this).balance);
    ivault.tokenBuy(token, msg.sender);
  }

  function sellBullTokens(
    address vault,
    uint256 amount,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 deadline
  ) public ensure(deadline) {
    vaultInterface ivault = vaultInterface(vault);
    address token = ivault.getBullToken();
    ivault.updatePrice();

    IERC20 itoken = IERC20(token);
    uint256 price = ivault.getPrice(token);
    require(price >= minPrice && price <= maxPrice, 'SynLevRouter: TOKEN PRICE OUT OF RANGE');
    require(itoken.transferFrom(msg.sender, vault, amount));
    ivault.tokenSell(token, msg.sender);
  }

  function buyBearTokens(
    address payable vault,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 deadline
  ) public payable ensure(deadline) {
    vaultInterface ivault = vaultInterface(vault);
    address token = ivault.getBearToken();
    ivault.updatePrice();
    uint256 price = ivault.getPrice(token);
    require(price >= minPrice && price <= maxPrice, 'SynLevRouter: TOKEN PRICE OUT OF RANGE');
    vault.transfer(address(this).balance);
    ivault.tokenBuy(token, msg.sender);
  }

  function sellBearTokens(
    address vault,
    uint256 amount,
    uint256 minPrice,
    uint256 maxPrice,
    uint256 deadline
  ) public ensure(deadline) {
    vaultInterface ivault = vaultInterface(vault);
    address token = ivault.getBearToken();
    ivault.updatePrice();
    IERC20 itoken = IERC20(token);
    uint256 price = ivault.getPrice(token);
    require(price >= minPrice && price <= maxPrice, 'SynLevRouter: TOKEN PRICE OUT OF RANGE');
    require(itoken.transferFrom(msg.sender, vault, amount));
    ivault.tokenSell(token, msg.sender);
  }



}

