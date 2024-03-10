// SPDX-License-Identifier: --🦉--

pragma solidity ^0.8.0;

interface WiseTokenInterface {

    function currentWiseDay()
        external view
        returns (uint64);

    function approve(
        address _spender,
        uint256 _value
    )
        external
        returns (bool success);

    function generateID(
        address x,
        uint256 y,
        bytes1 z
    )
        external
        pure
        returns (bytes16 b);

    function createStakeWithETH(
        uint64 _lockDays,
        address _referrer
    )
        external
        payable
        returns (bytes16, uint256, bytes16 referralID);

    function createStakeWithToken(
        address _tokenAddress,
        uint256 _tokenAmount,
        uint64 _lockDays,
        address _referrer
    )
        external
        returns (bytes16, uint256, bytes16 referralID);

    function createStake(
        uint256 _stakedAmount,
        uint64 _lockDays,
        address _referrer
    )
        external
        returns (bytes16, uint256, bytes16 referralID);

    function endStake(
        bytes16 _stakeID
    )
        external
        returns (uint256);

    function checkMatureStake(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (bool isMature);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function checkStakeByID(
        address _staker,
        bytes16 _stakeID
    )
        external
        view
        returns (
            uint256 startDay,
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
        );
}
