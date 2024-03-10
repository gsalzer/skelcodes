pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IQuack is IERC20Upgradeable {
    function burnFrom(address from, uint256 amount) external;
    function initialize(string memory, string memory) external;
    function mint(address, uint256) external;
    function grantRole(bytes32, address) external;
    // function balanceOf(address account) external;
}
