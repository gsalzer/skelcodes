pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IStEth is IERC20 {
    function submit(address) external payable returns (uint256);
}
