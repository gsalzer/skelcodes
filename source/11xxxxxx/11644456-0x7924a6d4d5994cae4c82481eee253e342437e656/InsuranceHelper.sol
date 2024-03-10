// SPDX-License-Identifier: --🦉--

pragma solidity ^0.8.0;

import './InsuranceDeclaration.sol';

contract InsuranceHelper is InsuranceDeclaration {

    //  WISE INSURANCE (INTERNAL FUNCTIONS)  //
    //  -------------------------------------

	function _increaseTotalStaked(
	    uint256 _amount
	)
	    internal
	{
	    totalStaked =
	    totalStaked + _amount;
	}

	function _decreaseTotalStaked(
	    uint256 _amount
	)
	    internal
	{
	    totalStaked =
	    totalStaked - _amount;
	}

	function _increaseTotalCovers(
	    uint256 _amount
	)
	    internal
	{
	    totalCovers =
	    totalCovers + _amount;
	}

	function _decreaseTotalCovers(
	    uint256 _amount
	)
	    internal
	{
	    totalCovers =
	    totalCovers - _amount;
	}

	function _increaseTotalBufferStaked(
	    uint256 _amount
	)
	    internal
	{
	    totalBufferStaked =
	    totalBufferStaked + _amount;
	}

	function _decreaseTotalBufferStaked(
	    uint256 _amount
	)
	    internal
	{
	    totalBufferStaked =
	    totalBufferStaked - _amount;
	}

	function _increaseTotalMasterProfits(
	    uint256 _amount
	)
	    internal
	{
	    totalMasterProfits =
	    totalMasterProfits + _amount;
	}

	function _decreaseTotalMasterProfits(
	    uint256 _amount
	)
	    internal
	{
	    totalMasterProfits =
	    totalMasterProfits > _amount ?
	    totalMasterProfits - _amount : 0;
	}

    function _increaseActiveInsuranceStakeCount()
        internal
    {
        activeInsuranceStakeCount++;
    }

    function _decreaseActiveInsuranceStakeCount()
        internal
    {
        activeInsuranceStakeCount--;
    }

    function _increaseActiveOwnerlessStakeCount()
        internal
    {
        activeOwnerlessStakeCount++;
    }

    function _decreaseActiveOwnerlessStakeCount()
        internal
    {
        activeOwnerlessStakeCount--;
    }

    function _increaseActiveBufferStakeCount()
        internal
    {
        activeBufferStakeCount++;
    }

    function _decreaseActiveBufferStakeCount()
        internal
    {
        activeBufferStakeCount--;
    }

    function _increaseOwnerlessStakeCount()
        internal
    {
        ownerlessStakeCount++;
    }

    function _increaseBufferStakeCount()
        internal
    {
        bufferStakeCount++;
    }

    function _trackOwnerlessStake(
        address _originalOwner,
        uint256 _stakeIndex
    )
        internal
    {
        ownerlessStakes[ownerlessStakeCount].stakeIndex = _stakeIndex;
        ownerlessStakes[ownerlessStakeCount].originalOwner = _originalOwner;
    }

    function _increaseInsuranceStakeCounts(
        address _staker
    )
        internal
    {
        insuranceStakeCount++;
        insuranceStakeCounts[_staker]++;
    }

    function _increasePublicDebth(
        uint256 _amount
    )
        internal
    {
        totalPublicDebth =
        totalPublicDebth + _amount;
    }

    function _decreasePublicDebth(
        uint256 _amount
    )
        internal
    {
        totalPublicDebth =
        totalPublicDebth - _amount;
    }

    function _increasePublicReward(
        address _contributor,
        uint256 _amount
    )
        internal
    {
        publicReward[_contributor] =
        publicReward[_contributor] + _amount;
    }

    function _decreasePublicReward(
        address _contributor,
        uint256 _amount
    )
        internal
    {
        publicReward[_contributor] =
        publicReward[_contributor] - _amount;
    }

    function _increasePublicRewards(
        uint256 _amount
    )
        internal
    {
        totalPublicRewards =
        totalPublicRewards + _amount;
    }

    function _decreasePublicRewards(
        uint256 _amount
    )
        internal
    {
        totalPublicRewards =
        totalPublicRewards - _amount;
    }

    function _renounceStakeOwnership(
        address _staker,
        uint256 _stakeIndex
    )
        internal
    {
        insuranceStakes[_staker][_stakeIndex].currentOwner = ZERO_ADDRESS;
    }

    function _calculateEmergencyAmount(
        uint256 _stakedAmount,
        uint256 _principalCut
    )
        internal
        pure
        returns (uint256)
    {
        uint256 percent = 100 - _principalCut;
        return _stakedAmount * percent / 100;
    }

    function _calculateMatureAmount(
        uint256 _stakedAmount,
        uint256 _bufferAmount,
        uint256 _principalCut
    )
        internal
        pure
        returns (uint256)
    {
        uint256 percent = 100 - _principalCut;
        return (_stakedAmount + _bufferAmount) * percent / 100;
    }

    function _deactivateStake(
        address _staker,
        uint256 _stakeIndex
    )
        internal
    {
        insuranceStakes[_staker][_stakeIndex].isActive = false;
    }

    function stakesPagination(
        address _staker,
        uint256 _offset,
        uint256 _length
    )
        external
        view
        returns (bytes16[] memory _stakes)
    {
        uint256 start = _offset > 0 &&
            insuranceStakeCounts[_staker] > _offset ?
            insuranceStakeCounts[_staker] - _offset : insuranceStakeCounts[_staker];

        uint256 finish = _length > 0 &&
            start > _length ?
            start - _length : 0;

        uint256 i;

        _stakes = new bytes16[](start - finish);

        for (uint256 _stakeIndex = start; _stakeIndex > finish; _stakeIndex--) {
            bytes16 _stakeID = getStakeID(_staker, _stakeIndex - 1);
            if (insuranceStakes[_staker][_stakeIndex - 1].stakedAmount > 0) {
                _stakes[i] = _stakeID; i++;
            }
        }
    }

    //  WISE INSURANCE (PUBLIC FUNCTIONS)  //
    //  -------------------------------------

    function getBufferAmount(
        address _staker,
        uint256 _stakeIndex

    )
        public
        view
        returns (uint256)
    {
        return insuranceStakes[_staker][_stakeIndex].bufferAmount;
    }

    function getEmergencyAmount(
        address _staker,
        uint256 _stakeIndex

    )
        public
        view
        returns (uint256)
    {
        return insuranceStakes[_staker][_stakeIndex].emergencyAmount;
    }

    function getMatureAmount(
        address _staker,
        uint256 _stakeIndex

    )
        public
        view
        returns (uint256)
    {
        return insuranceStakes[_staker][_stakeIndex].matureAmount;
    }

    function getStakedAmount(
        address _staker,
        uint256 _stakeIndex

    )
        public
        view
        returns (uint256)
    {
        return insuranceStakes[_staker][_stakeIndex].stakedAmount;
    }

    function getStakeData(
        uint256 _ownerlessStakeIndex
    )
        public
        view
        returns (address, uint256)
    {
        return (
            ownerlessStakes[_ownerlessStakeIndex].originalOwner,
            ownerlessStakes[_ownerlessStakeIndex].stakeIndex
        );
    }

    function checkActiveStake(
        address _staker,
        uint256 _stakeIndex
    )
        public
        view
        returns (bool)
    {
        return insuranceStakes[_staker][_stakeIndex].isActive;
    }

    function checkOwnership(
        address _staker,
        uint256 _stakeIndex
    )
        public
        view
        returns (bool)
    {
        return insuranceStakes[_staker][_stakeIndex].currentOwner == _staker;
    }

    function checkOwnerlessStake(
        address _staker,
        uint256 _stakeIndex
    )
        public
        view
        returns (bool)
    {
        return insuranceStakes[_staker][_stakeIndex].currentOwner == ZERO_ADDRESS;
    }

    function applyFee(
        uint256 _totalReward,
        uint256 _interestCut
    )
        public
        pure
        returns (uint256)
    {
        uint256 percent = 100 - _interestCut;
        return _totalReward * percent / 100;
    }

    function penaltyFee(
        uint256 _toReturn,
        uint256 _matureLevel
    )
        public
        view
        returns (uint256)
    {
        uint256 penaltyPercent;

        if (_matureLevel <= penaltyThresholdB) {
            penaltyPercent = penaltyB;
        }

        if (_matureLevel <= penaltyThresholdA) {
            penaltyPercent = penaltyA;
        }

        uint256 percent = 100 - penaltyPercent;
        return _toReturn * percent / 100;
    }

    function checkMatureLevel(
        address _staker,
        bytes16 _stakeID
    )
        public
        view
        returns (uint256)
    {

        (   uint256 startDay,
            uint256 lockDays,
            uint256 finalDay,
            uint256 closeDay,
            uint256 scrapeDay,
            uint256 stakedAmount,
            uint256 stakesShares,
            uint256 rewardAmount,
            uint256 penaltyAmount,
            bool isActive,
            bool isMature
        ) = WISE_CONTRACT.checkStakeByID(
            _staker,
            _stakeID
        );

        return 100 - (_daysLeft(WISE_CONTRACT.currentWiseDay(), finalDay) * 100 / lockDays);
    }

    function _daysLeft(
        uint256 _startDate,
        uint256 _endDate
    )
        internal
        pure
        returns (uint256)
    {
        return _startDate > _endDate ? 0 : _endDate - _startDate;
    }

    function getStakeID(
        address _staker,
        uint256 _stakeIndex

    )
        public
        view
        returns (bytes16)
    {
        return insuranceStakes[_staker][_stakeIndex].stakeID;
    }

    //  WISE INSURANCE (EXTERNAL MASTER FUNCTIONS)  //
    //  -------------------------------------

    function enablePublicContribution()
        external
        onlyMaster
    {
        allowPublicContributions = true;
        emit PublicContributionsOpened(true);
    }

    function disablePublicContribution()
        external
        onlyMaster
    {
        allowPublicContributions = false;
        emit PublicContributionsOpened(false);
    }

    function switchBufferStakeInterest(
        bool _asDeveloperFunds
    )
        external
        onlyMaster
    {
        getBufferStakeInterest = _asDeveloperFunds;
    }

    bytes4 private constant TRANSFER = bytes4(
        keccak256(
            bytes(
                'transfer(address,uint256)'
            )
        )
    );

    bytes4 private constant TRANSFER_FROM = bytes4(
        keccak256(
            bytes(
                'transferFrom(address,address,uint256)'
            )
        )
    );

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            TRANSFER_FAILED
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint _value
    )
        internal
    {
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(
                TRANSFER_FROM,
                _from,
                _to,
                _value
            )
        );

        require(
            success && (
                data.length == 0 || abi.decode(
                    data, (bool)
                )
            ),
            TRANSFER_FAILED
        );
    }
}
