pragma solidity 0.5.10;

interface BCF {
	function totalEthereumBalance() external view returns (uint256);
	function totalSupply() external view returns (uint256);
	function buyPrice() external view returns (uint256);
	function sellPrice() external view returns (uint256);
	function calculateEthereumReceived(uint256 _tokensToSell) external view returns (uint256);
	function balanceOf(address _customer) external view returns (uint256);
	function dividendsOf(address _customer) external view returns (uint256);
}

contract QBCF {

	BCF private bcf;

	constructor(address _BCF_address) public {
		bcf = BCF(_BCF_address);
	}

	function getGlobalInfo() public view returns (uint256 ethereumBalance, uint256 totalSupply, uint256 buyPrice, uint256 sellPrice) {
		return (bcf.totalEthereumBalance(), bcf.totalSupply(), bcf.buyPrice(), bcf.sellPrice());
	}

	function getCustomerInfo(address _customer) public view returns (uint256 customerBalance, uint256 customerDividends, uint256 liquidTotal) {
		customerBalance = bcf.balanceOf(_customer);
		customerDividends = bcf.dividendsOf(_customer);
		liquidTotal = bcf.calculateEthereumReceived(customerBalance) + customerDividends;
	}
}
