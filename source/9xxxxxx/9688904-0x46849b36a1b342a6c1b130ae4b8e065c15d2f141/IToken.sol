pragma solidity ^0.5.1;

/**
 * Interface of the ERC223Token standard as defined in the EIP.
 */

contract IToken {
    
    /**
     * Returns the balance of the `who` address.
     */
    function balanceOf(address who) public view returns (uint);
        
    /**
     * Transfers `value` tokens from `msg.sender` to `to` address
     * and returns `true` on success.
     */
    function transfer(address to, uint value) public returns (bool success);
        
    /**
     * Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint value, bytes memory data) public returns (bool success);
     
     /**
     * Event that is fired on successful transfer.
     */
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

