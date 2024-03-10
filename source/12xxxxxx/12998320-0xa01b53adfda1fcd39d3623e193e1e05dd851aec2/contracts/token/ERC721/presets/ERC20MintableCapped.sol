// contracts/NetworkToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NetworkToken is ERC20Capped, Ownable {
    
    constructor(uint256 _hard_cap) ERC20("Unifty Network Token", "UNT") ERC20Capped(_hard_cap) {
        
    }

    /// @notice Creates _amount token to _to. Must only be called by the owner (UniftyGovernance).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
