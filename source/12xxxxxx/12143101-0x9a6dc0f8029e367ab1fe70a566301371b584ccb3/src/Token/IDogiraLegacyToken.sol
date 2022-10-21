pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IDogira is IERC20 {
    function getFeeless(address account) external view returns (bool);
}

