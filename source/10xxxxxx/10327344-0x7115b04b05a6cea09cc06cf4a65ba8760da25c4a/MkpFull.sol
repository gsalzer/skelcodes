pragma solidity ^0.5.1;

import "./MkpERC20.sol";

contract MkpFull is MkpERC20 {
	uint256 public minEthers = 10 finney;
	
	constructor(
		uint256 _initialSupply,
        string memory _name,
        string memory _symbol
		) public MkpERC20(_initialSupply, _name, _symbol) {}
	
	/**
     * Set contract minimal wei balance to enable withdraw ethers
     *
	 * @param weis Minimal contract balance in weis
     */
    function setMinEthers(uint256 weis) public onlyOwner {
        minEthers = weis;
    }

	/**
     * transfers all ethers from contract address to the owner address
     *
     */
	function withdrawEther() public onlyOwner returns (bool success) {
		if (address(this).balance < minEthers) {
			return false;
		}
		//send ether from contract account
		owner.transfer(address(this).balance);
		return true;
    }
	
	/**
     * Send tokens from contract balance to client account
     *
     * Internal function, can be called from the contract and it's children contracts only
     */
    function fundClient(address _client, uint256 _amount) internal {
		if(balanceOf[address(this)] >= _amount) {
			_transfer(address(this), _client, _amount);
		}
		else {
			_mintToken(_client, _amount);
		}
	}
	
	/**
     * Send tokens from contract balance to client account
     *
     * @param _client account to send tokens
	 * @param _amount number of token minimal units (10**(-18)) to send
     */
    function buyDeal(address _client, uint256 _amount) public onlyOwner returns (bool success) {
		fundClient(_client, _amount);
		return true;
	}
	
	/**
     * Send tokens to contract account
     *
	 * @param _amount number of token minimal units (10**(-18)) to send
     */
    function sellDeal(uint256 _amount) public returns (bool success) {
		_transfer(msg.sender, address(this), _amount);
        return true;
	}
}
