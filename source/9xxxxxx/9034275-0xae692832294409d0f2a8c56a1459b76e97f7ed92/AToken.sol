pragma solidity ^0.5.0;


import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./Pausable.sol";


contract AToken is Ownable, ERC20, ERC20Detailed, Pausable {
        uint256 private total_supply = 100000000;
        string private token_name = "AuditStarter";
        string private token_symbol = "AUDIT";

    constructor (

        ) 
    public ERC20Detailed(token_name, token_symbol , 18) {
        _mint(_msgSender(), total_supply * (10 ** uint256(decimals())));
    }
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
