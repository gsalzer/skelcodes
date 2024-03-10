pragma solidity ^0.4.26;

import "./IERC20.sol";
import "./Owned.sol";
import "./SafeMathLib.sol";

/**
 * @dev Fiatech FITH token sale contract.
 */
contract FITHTokenSale is Owned
{
	using SafeMathLib for uint;
	
    IERC20 public tokenContract;
	
	uint256 public tokenPrice;
    uint256 public tokensSold;
	
	// tokens bought event raised when buyer purchases tokens
    event TokensBought(address _buyer, uint256 _amount, uint256 _tokensSold);
	
	// token price update event
	event TokenPriceUpdate(address _admin, uint256 _tokenPrice);
	
	
	
	/**
	 * @dev Constructor
	 */
    constructor(IERC20 _tokenContract, uint256 _tokenPrice) public
	{
		require(_tokenPrice > 0, "_tokenPrice greater than zero required");
		
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }
	
	function tokensAvailable() public view returns (uint) {
		return tokenContract.balanceOf(address(this));
	}
	
	
	
	function _buyTokens(uint256 _numberOfTokens) internal returns(bool) {
        require(tokensAvailable() >= _numberOfTokens, "insufficient tokens on token-sale contract");
        require(tokenContract.transfer(msg.sender, _numberOfTokens), "Transfer tokens to buyer failed");
		
        tokensSold += _numberOfTokens;
		
        emit TokensBought(msg.sender, _numberOfTokens, tokensSold);
		return true;
    }
	
	function updateTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0 && _tokenPrice != tokenPrice, "Token price must be greater than zero and different than current");
        
		tokenPrice = _tokenPrice;
		emit TokenPriceUpdate(owner, _tokenPrice);
    }
	
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == (_numberOfTokens * tokenPrice), "Incorrect number of tokens");
        _buyTokens(_numberOfTokens);
    }
	
    function endSale() public onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))), "Transfer token-sale token balance to owner failed");
		
        // Just transfer the ether balance to the owner
        owner.transfer(address(this).balance);
    }
	
	/**
	 * Accept ETH for tokens
	 */
    function () external payable {
		uint tks = (msg.value).div(tokenPrice);
		_buyTokens(tks);
    }
	
	
	
	/**
	 * @dev Owner can transfer out (recover) any ERC20 tokens accidentally sent to this contract.
	 * @param tokenAddress Token contract address we want to recover lost tokens from.
	 * @param tokens Amount of tokens to be recovered, usually the same as the balance of this contract.
	 * @return bool
	 */
    function recoverAnyERC20Token(address tokenAddress, uint tokens) external onlyOwner returns (bool ok) {
		ok = IERC20(tokenAddress).transfer(owner, tokens);
    }
}
