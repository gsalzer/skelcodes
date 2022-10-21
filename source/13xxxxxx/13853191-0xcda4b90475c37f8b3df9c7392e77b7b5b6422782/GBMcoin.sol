pragma solidity ^0.6.0;
 
interface ERC20Token {
 
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function allowance(address owner, address spender) external view returns (uint256);
 
	function transfer(address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
}
 
contract GBMcoin is ERC20Token {
 
	string public constant name = "GBM coin";
	string public constant symbol = "GBM";
	uint8 public constant decimals = 18;
	uint256 public totalSupply_ = 1000000000000000000000000;
 
	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
 
	mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) allowed;
 
	using SafeMath for uint256;
 
   constructor() public {
	balances[msg.sender] = totalSupply_;
	}
 
	function totalSupply() public override view returns (uint256) {
	return totalSupply_;
	}
 
	function balanceOf(address tokenOwner) public override view returns (uint256) {
    	return balances[tokenOwner];
	}
 
	function allowance(address owner, address delegate) public override view returns (uint) {
    	return allowed[owner][delegate];
	}
 
	function transfer(address receiver, uint256 numTokens) public override returns (bool) {
    	require(numTokens <= balances[msg.sender]);
    	balances[msg.sender] = balances[msg.sender].sub(numTokens);
    	balances[receiver] = balances[receiver].add(numTokens);
    	emit Transfer(msg.sender, receiver, numTokens);
    	return true;
	}
 
	function approve(address delegate, uint256 numTokens) public override returns (bool) {
    	allowed[msg.sender][delegate] = numTokens;
    	emit Approval(msg.sender, delegate, numTokens);
    	return true;
	}
 
	function transferFrom(address sender, address recipient, uint256 numTokens) public override returns (bool) {
    	require(numTokens <= balances[sender]);
    	require(numTokens <= allowed[sender][msg.sender]);
 
    	balances[sender] = balances[sender].sub(numTokens);
    	allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(numTokens);
    	balances[recipient] = balances[recipient].add(numTokens);
    	emit Transfer(sender, recipient, numTokens);
    	return true;
	}
	
}
 
library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
  	assert(b <= a);
  	return a - b;
	}
 
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
  	uint256 c = a + b;
  	assert(c >= a);
  	return c;
	}
}
