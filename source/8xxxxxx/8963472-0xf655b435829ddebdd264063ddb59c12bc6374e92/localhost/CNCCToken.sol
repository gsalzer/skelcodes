pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract CNCCToken is Ownable,ERC20,ERC20Detailed {
    using SafeMath for uint256;

    constructor(uint256 totalSupply) ERC20Detailed("Chain Node Chain Coin", "CNCC", 18) public {
        _mint(msg.sender, totalSupply.mul(uint256(1000000000000000000)));
    }
}

