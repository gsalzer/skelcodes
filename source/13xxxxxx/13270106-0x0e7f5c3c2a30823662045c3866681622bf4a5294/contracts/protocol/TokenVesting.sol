// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../openzeppelin/access/AccessControl.sol";
import "../openzeppelin/utils/math/SafeMath.sol";
import "../openzeppelin/token/ERC20/SafeERC20.sol";
import "../openzeppelin/token/ERC20/IERC20.sol";
import "../sablierhq/Sablier.sol";
import "./ITokenVesting.sol";

/**
 * @title TokenVesting contract for linearly vesting tokens to the respective vesting beneficiary
 * @dev This contract receives accepted proposals from the Manager contract, and pass it to sablier contract
 * @dev all the tokens to be vested by the vesting beneficiary. It releases these tokens when called
 * @dev upon in a continuous-like linear fashion.
 * @notice This contract use https://github.com/sablierhq/sablier-smooth-contracts/blob/master/contracts/Sablier.sol
 */
contract TokenVesting is ITokenVesting, AccessControl {
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	address sablier;
	uint256 constant CREATOR_IX = 0;
	uint256 constant ROLL_IX = 1;
	uint256 constant REFERRAL_IX = 2;

	uint256 public constant DAYS_IN_SECONDS = 24 * 60 * 60;
	mapping(address => VestingInfo) public vestingInfo;
	mapping(address => mapping(uint256 => Beneficiary)) public beneficiaries;
	mapping(address => address[]) public beneficiaryTokens;

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(
			hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
			"Ownable: caller is not the owner"
		);
		_;
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			"Ownable: new owner is the zero address"
		);
		grantRole(DEFAULT_ADMIN_ROLE, newOwner);
		revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	constructor(address newOwner) {
		_setupRole(DEFAULT_ADMIN_ROLE, newOwner);
	}

	function setSablier(address _sablier) external onlyOwner {
		sablier = _sablier;
	}

	/**
	 * @dev Method to add a token into TokenVesting
	 * @param _token address Address of token
	 * @param _beneficiaries address[3] memory Address of vesting beneficiary
	 * @param _proportions uint256[3] memory Proportions of vesting beneficiary
	 * @param _vestingPeriodInDays uint256 Period of vesting, in units of Days, to be converted
	 * @notice This emits an Event LogTokenAdded which is indexed by the token address
	 */
	function addToken(
		address _token,
		address[3] calldata _beneficiaries,
		uint256[3] calldata _proportions,
		uint256 _vestingPeriodInDays
	) external override onlyOwner {
		uint256 duration = uint256(_vestingPeriodInDays).mul(DAYS_IN_SECONDS);
		require(duration > 0, "VESTING: period can't be zero");
		uint256 stopTime = block.timestamp.add(duration);
		uint256 initial = IERC20(_token).balanceOf(address(this));

		vestingInfo[_token] = VestingInfo({
			vestingBeneficiary: _beneficiaries[0],
			totalBalance: initial,
			beneficiariesCount: 3, // this is to create a struct compatible with any number but for now is always 3
			start: block.timestamp,
			stop: stopTime
		});

		IERC20(_token).approve(sablier, 2**256 - 1);
		IERC20(_token).approve(address(this), 2**256 - 1);

		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (_beneficiaries[i] == address(0)) {
				continue;
			}
			beneficiaries[_token][i].beneficiary = _beneficiaries[i];
			beneficiaries[_token][i].proportion = _proportions[i];

			uint256 deposit = _proportions[i];
			if (deposit == 0) {
				continue;
			}

			// we store the remaing to guarantee deposit be multiple of period. We send that remining at the end of period.
			uint256 remaining = deposit % duration;

			uint256 streamId =
				Sablier(sablier).createStream(
					_beneficiaries[i],
					deposit.sub(remaining),
					_token,
					block.timestamp,
					stopTime
				);

			beneficiaries[_token][i].streamId = streamId;
			beneficiaries[_token][i].remaining = remaining;
			beneficiaryTokens[_beneficiaries[i]].push(_token);
		}

		emit LogTokenAdded(_token, _beneficiaries[0], _vestingPeriodInDays);
	}

	function getBeneficiaryId(address _token, address _beneficiary)
		internal
		view
		returns (uint256)
	{
		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (beneficiaries[_token][i].beneficiary == _beneficiary) {
				return i;
			}
		}

		revert("VESTING: invalid vesting address");
	}

	function release(address _token, address _beneficiary) external override {
		uint256 ix = getBeneficiaryId(_token, _beneficiary);
		uint256 streamId = beneficiaries[_token][ix].streamId;
		if (!Sablier(sablier).isEntity(streamId)) {
			return;
		}
		uint256 balance = Sablier(sablier).balanceOf(streamId, _beneficiary);
		bool withdrawResult =
			Sablier(sablier).withdrawFromStream(streamId, balance);
		require(withdrawResult, "VESTING: Error calling withdrawFromStream");

		// if vesting duration already finish then release the final dust
		if (
			vestingInfo[_token].stop < block.timestamp &&
			beneficiaries[_token][ix].remaining > 0
		) {
			IERC20(_token).safeTransferFrom(
				address(this),
				_beneficiary,
				beneficiaries[_token][ix].remaining
			);
		}
	}

	function releaseableAmount(address _token)
		public
		view
		override
		returns (uint256)
	{
		uint256 total = 0;

		for (uint256 i = 0; i < vestingInfo[_token].beneficiariesCount; i++) {
			if (Sablier(sablier).isEntity(beneficiaries[_token][i].streamId)) {
				total =
					total +
					Sablier(sablier).balanceOf(
						beneficiaries[_token][i].streamId,
						beneficiaries[_token][i].beneficiary
					);
			}
		}

		return total;
	}

	function releaseableAmountByAddress(address _token, address _beneficiary)
		public
		view
		override
		returns (uint256)
	{
		uint256 ix = getBeneficiaryId(_token, _beneficiary);
		uint256 streamId = beneficiaries[_token][ix].streamId;
		return Sablier(sablier).balanceOf(streamId, _beneficiary);
	}

	function vestedAmount(address _token)
		public
		view
		override
		returns (uint256)
	{
		VestingInfo memory info = vestingInfo[_token];
		if (block.timestamp >= info.stop) {
			return info.totalBalance;
		} else {
			uint256 duration = info.stop.sub(info.start);
			return
				info.totalBalance.mul(block.timestamp.sub(info.start)).div(
					duration
				);
		}
	}

	function getVestingInfo(address _token)
		external
		view
		override
		returns (VestingInfo memory)
	{
		return vestingInfo[_token];
	}

	function updateVestingAddress(
		address _token,
		uint256 ix,
		address _vestingBeneficiary
	) internal {
		if (
			vestingInfo[_token].vestingBeneficiary ==
			beneficiaries[_token][ix].beneficiary
		) {
			vestingInfo[_token].vestingBeneficiary = _vestingBeneficiary;
		}

		beneficiaries[_token][ix].beneficiary = _vestingBeneficiary;

		uint256 deposit = 0;
		uint256 remaining = 0;
		{
			uint256 streamId = beneficiaries[_token][ix].streamId;
			// if there's no pending this will revert and it's ok because has no sense to update the address
			uint256 pending =
				Sablier(sablier).balanceOf(streamId, address(this));

			uint256 duration = vestingInfo[_token].stop.sub(block.timestamp);
			deposit = pending.add(beneficiaries[_token][ix].remaining);
			remaining = deposit % duration;

			bool cancelResult =
				Sablier(sablier).cancelStream(
					beneficiaries[_token][ix].streamId
				);
			require(cancelResult, "VESTING: Error calling cancelStream");
		}

		uint256 streamId =
			Sablier(sablier).createStream(
				_vestingBeneficiary,
				deposit.sub(remaining),
				_token,
				block.timestamp,
				vestingInfo[_token].stop
			);
		beneficiaries[_token][ix].streamId = streamId;
		beneficiaries[_token][ix].remaining = remaining;

		emit LogBeneficiaryUpdated(_token, _vestingBeneficiary);
	}

	function setVestingAddress(
		address _vestingBeneficiary,
		address _token,
		address _newVestingBeneficiary
	) external override onlyOwner {
		uint256 ix = getBeneficiaryId(_token, _vestingBeneficiary);
		updateVestingAddress(_token, ix, _newVestingBeneficiary);
	}

	function setVestingReferral(
		address _vestingBeneficiary,
		address _token,
		address _vestingReferral
	) external override onlyOwner {
		require(
			_vestingBeneficiary == vestingInfo[_token].vestingBeneficiary,
			"VESTING: Only creator"
		);
		updateVestingAddress(_token, REFERRAL_IX, _vestingReferral);
	}

	function getAllTokensByBeneficiary(address _beneficiary)
		public
		view
		override
		returns (address[] memory)
	{
		return beneficiaryTokens[_beneficiary];
	}

	function releaseAll(address _beneficiary) public override {
		address[] memory array = beneficiaryTokens[_beneficiary];
		for (uint256 i = 0; i < array.length; i++) {
			this.release(array[i], _beneficiary);
		}
	}
}

