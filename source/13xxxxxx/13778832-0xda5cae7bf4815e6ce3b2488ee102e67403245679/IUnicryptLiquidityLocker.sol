pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

interface IUnicryptLiquidityLocker {
	function gFees() external view returns (
		uint256 ethFee,
		address secondaryFeeToken,
		uint256 secondaryTokenFee,
		uint256 secondaryTokenDiscount,
		uint256 liquidityFee,
		uint256 referralPercent,
		address referralToken,
		uint256 referralHold,
		uint256 referralDiscount
	);

	function lockLPToken(
		address _lpToken,
		uint256 _amount,
		uint256 _unlock_date,
		address payable _referral,
		bool _fee_in_eth,
		address payable _withdrawer
	) external payable;
}
