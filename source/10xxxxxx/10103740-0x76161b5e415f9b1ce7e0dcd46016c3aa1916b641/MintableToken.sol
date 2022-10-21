pragma solidity ^0.4.17;

import "./StandardToken.sol";

contract MintableToken is StandardToken {

    event TokensMinted(address indexed to , uint256 ammount);
    event MintingFinished();

    bool public mintingFinished;

    /**
     * Modifier makes a prerequisite check that the minting function and finish minting
     * function can be called prior to executing any of the code within the functions.
     */
    modifier canMint {
        require(!mintingFinished);
        _;
    }

    /**
     * Constructor initializes the total supply to zero.
     */
    function MintableToken() public {
        mintingFinished = false;
    }

    /**
     * Generates new tokens and sends them to a specified ETH address. This function is 
     * restricted and can only be called by the owner of the contract. In this case, the 
     * owner will be the ICO contract because it is the ICO contract which will deploy
     * the token contract. 
     * 
     * @param _addr The address of the recipient.
     * @param _value The amount of tokens to be minted.
     */
    function mintTokens(address _addr, uint256 _value) public onlyOwner canMint returns(bool){
        require(_addr != 0x0 && _value > 0);
        totalSupply = totalSupply.add(_value);
        balances[_addr] = balances[_addr].add(_value);
        Transfer(this, _addr, _value);
        TokensMinted (_addr, _value);
        return true;
    } 

    /**
     * Terminates the minting period permanently. This function is restricted and can
     * only be executed by the owner of the contract. 
     */
    function finishMinting() public onlyOwner canMint returns(bool) {
        mintingFinished = true;
        MintingFinished();
        return true;
    }
}
