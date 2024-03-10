pragma solidity ^0.4.26;

interface OrFeedInterface {
	// throws VM error: 'Error: Returned error: VM execution error.', solution: remove 'view' keyword from the interface for contract version 0.5.0 and above
	function getExchangeRate ( string fromSymbol, string toSymbol, string venue, uint256 amount ) external view returns ( uint256 );
	
	function getTokenDecimalCount ( address tokenAddress ) external view returns ( uint256 );
	function getTokenAddress ( string symbol ) external view returns ( address );
	function getSynthBytes32 ( string symbol ) external view returns ( bytes32 );
	function getForexAddress ( string symbol ) external view returns ( address );
	//function arb(address fundsReturnToAddress, address liquidityProviderContractAddress, string[] tokens,  uint256 amount, string[] exchanges) external payable returns (bool);
}

