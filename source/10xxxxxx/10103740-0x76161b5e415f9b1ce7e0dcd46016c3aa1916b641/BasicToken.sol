pragma solidity ^0.4.17;

import "./ERC20Basic.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract BasicToken is ERC20Basic, Ownable {

    using SafeMath for uint256;

    //Mapping keeps track of all token balances
    mapping(address => uint256) balances;

    /**
     * Modifier prevents short address attacks.
     * For more info check: https://ericrafaloff.com/analyzing-the-erc20-short-address-attack/
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    /**
     * Returns the balance of any given ETH address.
     *
     * @param _addr The address to be queried.
     */
    function balanceOf(address _addr) constant public returns (uint256) {
        return balances[_addr];
    }

    /**
     * Transfers EEE tokens from one address to another, given that the address which 
     * executes the transfer has enough tokens.
     *
     * @param _addr The address of the recipient. 
     * @param _value The amount of tokens to be sent.
     */
    function transfer(address _addr, uint _value) public onlyPayloadSize(2 * 32) returns (bool) {
        require(_addr != 0x0 && _value > 0 && balances[msg.sender] >= _value);
        balances[_addr] = balances[_addr].add(_value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        Transfer(msg.sender, _addr, _value);
        return true;
    }
} 
