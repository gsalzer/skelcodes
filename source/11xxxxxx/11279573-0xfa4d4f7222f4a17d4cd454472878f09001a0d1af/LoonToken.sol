pragma solidity 0.5.0;

import "./ERC20.sol"; 
import "./ERC20Detailed.sol";
import "./TokenLock.sol";

/**
 * @title LoonToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract LoonToken is ERC20, ERC20Detailed, TokenLock {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor (string memory name, string memory symbol, uint8 decimals, uint256 total)
        public ERC20Detailed (name, symbol, decimals ) {
        uint256 INITIAL_SUPPLY = total * (10 ** uint256(decimals));
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function() external payable { // don't send eth directly to token contract
        revert();
    }
    modifier onlyValidDestination(address to) {
        require(to != address(0x0),"onlyValidDestination:");
        require(to != address(this),"onlyValidDestination:");
        require(to != owner(),"onlyValidDestination:");
        _;
    }

    // modifiers
    // checks if the address can transfer tokens
    modifier canTransfer(address _sender, uint256 _value) {
        require(_sender != address(0),"canTransfer:");
        require((_sender == owner() || _sender == admin()) || (
            transferEnabled && (
            noTokenLocked ||
            canTransferIfLocked(_sender, _value)
            )
        )
        ,"canTransfer:" );
        _;
    }
    
    function setAdmin(address newAdmin) public onlyOwner {
        address oldAdmin = admin();
        uint256 total = totalSupply();
        super.setAdmin(newAdmin);
        if(oldAdmin!=address(0)) approve(oldAdmin, 0);
        approve(newAdmin, total);
    }

    function canTransferIfLocked(address _sender, uint256 _value) public view returns(bool) {
        uint256 mybalance = balanceOf(_sender);
        uint256 after_math = mybalance.sub(_value);
        return after_math >= getMinLockedAmount(_sender);
    }

     // override function using canTransfer on the sender address
    function transfer(address _to, uint256 _value)
     public onlyValidDestination(_to) canTransfer(msg.sender, _value) returns (bool success) {
        return super.transfer(_to, _value);
    }

    // transfer tokens from one address to another
    function transferFrom(address _from, address _to, uint256 _value)
     public onlyValidDestination(_to) canTransfer(_from, _value) returns (bool success) {
         return super.transferFrom(_from,_to, _value);
    }

    // {ERC20-_burnFrom} onlyOperator
    function burn(uint256 amount) public onlyOperator {
        _burn(_msgSender(), amount);
    }

}
