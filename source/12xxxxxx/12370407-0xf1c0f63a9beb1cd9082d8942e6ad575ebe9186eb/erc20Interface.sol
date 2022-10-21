pragma solidity ^0.4.24;

interface ERC20Interface {
		/*
		 => returns total supply of tokens
		 */
		function totalSupply() external view returns (uint256);
		
		/*
		 @owner = Token Owner
		 => returns value of balance
		 */
		function balanceOf( address owner ) external view returns ( uint256 );
				
		/*
		 @to = To address
		 @value = Ammount to transfer
		 => returns true if successful transfer / false if not
		 */
		function transfer( address to, uint256 value ) external returns ( bool );
		
		/*
		 @from = From address
		 @to = To address
		 @value = Ammount to transfer
		 => returns true for successful transfer
		 */
		function transferFrom( address from, address to, uint256 value ) external returns ( bool );
		
		/*
		 @owner = Token Owner address
		 @spender = Token Spender address
		 => returns allowance of owner to spender
		 */
		function allowance( address owner, address spender ) external view returns ( uint256 );
		
		/*
		 @spender = Spender address
		 @value = Value to for allowance
		 => returns true if approval successful
		 */
		function approve( address spender, uint256 value ) external returns ( bool );
		
		/*
		 @from = From address
		 @to = To address
		 @value = Ammount to transfer
		 => returns true for successful transfer
		 */
		event Transfer( address indexed from, address indexed to, uint256 value );
		
		/*
		 @owner = Owner address
		 @spender = Spender address
		 @value = Ammount approved to spend
		 => returns 
		 */
		event Approval( address indexed owner, address indexed spender, uint256 value );
}
