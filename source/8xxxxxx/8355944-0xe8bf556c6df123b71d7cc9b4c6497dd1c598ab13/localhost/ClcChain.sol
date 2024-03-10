pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ClcChain is Ownable,ERC20,ERC20Burnable,ERC20Detailed("Catalyst Coin","CLC", 6) {
    using SafeMath for uint256;

    //100000000
    constructor(uint256 totalSupply) public {
        _mint(msg.sender, totalSupply.mul(uint256(1000000)));
    }
}

