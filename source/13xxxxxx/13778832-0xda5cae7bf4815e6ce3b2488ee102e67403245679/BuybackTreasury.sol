pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./AccessControl.sol";
import "./IERC20.sol";
import "./IDEXRouter.sol";

contract BuybackTreasury is AccessControl {
	uint256 constant MAX_UINT = 2 ^ 256 - 1;
	address constant DEAD_ADDRESS = address(57005);
	IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

	IDEXRouter router;
	IERC20 token;

	uint256 public totalEthDeposited;
	uint256 public totalEthBoughtBack;
	uint256 public totalValueBoughtBack;

	event Deposit(uint256 amount);
	event Buyback(uint256 amount, uint256 value);

	constructor(address routerAddress, address tokenAddress, address ownerAddress) {
		router = IDEXRouter(routerAddress);
		token = IERC20(tokenAddress);

		_grantRole(DEFAULT_ADMIN_ROLE, address(token));
		_grantRole(DEFAULT_ADMIN_ROLE, ownerAddress);
	}

	function _getValueOfEthAmount(uint256 amount) private view returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = address(USDT);

		return router.getAmountsOut(amount, path)[1];
	}

	function _approveRouter(uint256 amount) private {
		require(token.approve(address(router), amount), "Router approval failed");
	}

	function _buy(uint256 amountIn) private returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = router.WETH();
		path[1] = address(token);

		uint256 previousBalance = token.balanceOf(address(this));

		_approveRouter(amountIn);
		router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : amountIn}(0, path, address(this), block.timestamp);

		return token.balanceOf(address(this)) - previousBalance;
	}

	function _addLiquidity(uint256 amountIn) private {
		uint256 ethForLiquidity = amountIn / 2;
		uint256 tokensForLiquidity = _buy(amountIn - ethForLiquidity);

		_approveRouter(tokensForLiquidity);
		router.addLiquidityETH{value : ethForLiquidity}(address(token), tokensForLiquidity, 0, 0, DEAD_ADDRESS, block.timestamp);
	}

	function buyback(uint256 amountIn) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(amountIn > 0, "Insufficient value sent");
		require(address(this).balance >= amountIn, "Insufficient balance");

		uint256 value = _getValueOfEthAmount(amountIn);

		_addLiquidity(amountIn);

		totalEthBoughtBack += amountIn;
		totalValueBoughtBack += value;

		emit Buyback(amountIn, value);
	}

	function deposit() external payable onlyRole(DEFAULT_ADMIN_ROLE) {
		totalEthDeposited += msg.value;
		emit Deposit(msg.value);
	}

	function setToken(address value) external onlyRole(DEFAULT_ADMIN_ROLE) {
		token = IERC20(value);
		_grantRole(DEFAULT_ADMIN_ROLE, address(token));
	}

	receive() external payable {}
}
