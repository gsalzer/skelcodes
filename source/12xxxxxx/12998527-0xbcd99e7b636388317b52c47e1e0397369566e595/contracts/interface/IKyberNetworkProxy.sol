pragma solidity 0.6.2;

import { IERC20 as ERC20 } from "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";

interface IKyberNetworkProxy {
    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view returns (uint expectedRate, uint slippageRate);
    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint);
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external payable returns(uint);
    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minRate) external returns(uint);
}

