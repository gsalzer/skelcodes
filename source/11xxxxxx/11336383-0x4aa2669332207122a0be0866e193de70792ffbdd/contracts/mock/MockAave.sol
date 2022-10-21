pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MockAave is ERC20 {
    using SafeMath for uint256;

    constructor() public ERC20("AAVE", "AAVE") {
        _mint(msg.sender, 1000e18);
    }

}
