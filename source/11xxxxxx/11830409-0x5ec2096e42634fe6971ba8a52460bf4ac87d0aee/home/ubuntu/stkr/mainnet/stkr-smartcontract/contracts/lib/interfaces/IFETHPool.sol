pragma solidity ^0.6.11;
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

interface IFETHPool is IERC20 {
    function mint(address account, uint256 amount) external returns(uint256);

    function depositFor(address user, uint256 amount) external;

    function deposit(uint256 amount) external;
}

