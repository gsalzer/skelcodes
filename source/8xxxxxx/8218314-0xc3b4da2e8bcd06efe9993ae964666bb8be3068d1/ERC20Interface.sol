pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    
    function balanceOf(address tokenOwner) external view returns (uint256);

    function allowance(address tokenOwner, address spender) external view returns (uint256);
    function approve(address spender, uint256 tokens) external returns (bool success);

    function transfer(address to, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256 total);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
	
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
	
    event Freeze(address indexed from, uint256 tokens);
	
    event Unfreeze(address indexed from, uint256 tokens);
    
}
