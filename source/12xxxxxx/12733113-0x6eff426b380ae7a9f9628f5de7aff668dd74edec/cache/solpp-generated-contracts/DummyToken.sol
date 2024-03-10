pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



/**
    *@title DummyToken contract
    * @dev It is deployed only when the Migrate function is called. 
    *  Owner of DummyToken contract is MIgrator contract.
**/
contract DummyToken is ERC20("Dummy.Token", "DMT"), Ownable {

    uint256 MAX_SUPPLY = 10000000000000000 ether;

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        // Make sure max supply never passed
        require(totalSupply() + (_amount) <= MAX_SUPPLY, 'Max supply reached');

        _mint(_to, _amount);
    }
}
