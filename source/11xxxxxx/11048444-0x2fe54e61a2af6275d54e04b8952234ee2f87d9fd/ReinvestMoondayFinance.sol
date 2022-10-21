pragma solidity ^0.5.10;

import "./SafeMath.sol";
import "./ERC20Interface.sol";
import "./Ownable.sol";


contract ReinvestMoondayFinance is Ownable {
	using SafeMath for uint256;
	
	ERC20Interface MoondayToken;
	
	address payable public moondayFinanceContract;
	
	event Reinvested(uint256 amount);
	
	constructor(address _MoondayToken) public {
        owner = msg.sender;
        MoondayToken = ERC20Interface(_MoondayToken);
        // MoondayToken = ERC20Interface(0x1ad606adde97c0c28bd6ac85554176bc55783c01);
    }

	function setMoondayContractAddress(address payable _moondayFinanceContract) public onlyOwner{ 
		moondayFinanceContract = _moondayFinanceContract;
	}
	
	function reinvest() public {
		require(moondayFinanceContract != address(0), "Invalid Moonday Capital Contract Address");
		require(MoondayToken.balanceOf(address(this)) > 0, "Invalid Token Balance to reinvest");
		uint256 amount = MoondayToken.balanceOf(address(this));
		MoondayToken.transfer(moondayFinanceContract, amount);
		emit Reinvested(amount);
	}
}
