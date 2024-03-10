pragma solidity ^0.5.0;

interface OrFeedInterface {
	// throws VM error: 'Error: Returned error: VM execution error.', solution: remove 'view' keyword from the interface for contract version 0.5.0 and above
	function getExchangeRate ( string calldata fromSymbol, string calldata toSymbol, string calldata venue, uint256 amount ) external returns ( uint256 );
	
	function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
	function getTokenAddress ( string calldata symbol ) external view returns ( address );
	function getSynthBytes32 ( string calldata symbol ) external view returns ( bytes32 );
	function getForexAddress ( string calldata symbol ) external view returns ( address );
	//function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] tokens,  uint256 amount, string[] exchanges) external payable returns (bool);
}

