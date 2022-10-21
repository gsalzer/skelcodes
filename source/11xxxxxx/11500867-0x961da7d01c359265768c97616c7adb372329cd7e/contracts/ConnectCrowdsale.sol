pragma solidity >=0.5.0 <0.7.0;

import { Crowdsale } from "ozcontracts250/crowdsale/Crowdsale.sol";
import { AllowanceCrowdsale } from "ozcontracts250/crowdsale/emission/AllowanceCrowdsale.sol";
import { TimedCrowdsale } from "ozcontracts250/crowdsale/validation/TimedCrowdsale.sol";
import { IERC20 } from "ozcontracts250/token/ERC20/IERC20.sol";
import { IIndexedUniswapV2Oracle } from "./IIndexedUniswapV2Oracle.sol";

contract ConnectCrowdsale is Crowdsale, AllowanceCrowdsale, TimedCrowdsale {
  address public oracle;
  address constant USDC_ADDRESS = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  constructor(
    address payable wallet,
    IERC20 token,
    uint256 openingTime,
    uint256 closingTime,
    address _oracle
  ) public AllowanceCrowdsale(wallet) TimedCrowdsale(openingTime, closingTime) Crowdsale(1, wallet, token) {
    oracle = _oracle;
  }
  function updatePrice() internal {
    IIndexedUniswapV2Oracle(oracle).updatePrice(USDC_ADDRESS);
  }
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate());
  }
  function rate() public view returns (uint256) {
    return uint256(1 ether).div(uint256(IIndexedUniswapV2Oracle(oracle).computeAverageEthForTokens(USDC_ADDRESS, 1e5, 0, 60*60*24*2))); // take two day moving average
  }
  function() external payable {
    updatePrice();
    buyTokens(_msgSender());
  }
}

