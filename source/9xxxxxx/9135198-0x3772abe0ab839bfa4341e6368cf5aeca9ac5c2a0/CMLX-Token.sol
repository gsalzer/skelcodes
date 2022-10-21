pragma solidity ^0.5.15;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";

/**
 * @dev This definitions allow calling contracts that handle token transfers
 * https://github.com/ethereum/ethereum-org/blob/master/solidity/token-advanced.sol
 * https://github.com/ethereum/EIPs/issues/677
 */
contract ContractFallbacks {
    function receiveApproval(address from, uint256 _amount, address _token, bytes memory _data) public;
	function onTokenTransfer(address from, uint256 amount, bytes memory data) public returns (bool success);
}

contract CMLX is ERC20, ERC20Detailed, ERC20Burnable {
    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        _name = "China Marshal Lion";       //set namme of token
        _symbol = "CMLX";                   //set symbol of token
        _decimals = 18;                     //decimal places

        _totalSupply = 1000000000000000000000000000;    //1B(10^9) tokens and 18 decimals (10^18);
        _balances[msg.sender] = _totalSupply;           //all tokens to creator
        emit Transfer(address(0), msg.sender, _totalSupply);    //inform wallets about new token
    }

    /**
	 * @dev function that allow to approve for transfer and call contract in one transaction
     * approveAndCAll https://github.com/ethereum/ethereum-org/blob/master/solidity/token-advanced.sol
     * receiveApproval should fail on eror, as no value is returned
	 * @param _spender contract address
	 * @param _amount amount of tokens
	 * @param _extraData optional encoded data to send to contract
	 * @return True if function call was succesfull
	 */
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success)
	{
        require(approve(_spender, _amount), "ERC20: Approve unsuccesfull");
        ContractFallbacks(_spender).receiveApproval(msg.sender, _amount, address(this), _extraData);
        return true;
    }

    /**
     * @dev function that transer tokens to diven address and call function on that address
     * transferAndCall standard https://github.com/ethereum/EIPs/issues/677
     * if onTokenTransfer fails returning false transfer is done anyway, so called contract should allow to call with tokens send already
     * @param _to address to send tokens and call
     * @param _value amount of tokens
     * @param _data optional extra data to process in calling contract
     * @return success True if all succedd
     */
	function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool success)
  	{
  	    _transfer(msg.sender, _to, _value);
		return ContractFallbacks(_to).onTokenTransfer(msg.sender, _value, _data);
  	}

}

