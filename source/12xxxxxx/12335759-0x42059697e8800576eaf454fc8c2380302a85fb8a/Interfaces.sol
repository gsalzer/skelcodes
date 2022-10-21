// SPDX-License-Identifier: --GRISE--

pragma solidity =0.7.6;

interface IUniswapRouterV2 {

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (
        uint[] memory amounts
    );
}

interface IGriseToken {

    function currentGriseDay()
        external view
        returns (uint64);

    function balanceOfStaker(
        address account
    ) external view returns (uint256);

    function approve(
        address _spender,
        uint256 _value
    ) external returns (bool success);

    function totalSupply() 
        external view 
        returns (uint256);

    function mintSupply(
        address _investorAddress,
        uint256 _amount
    ) external;

    function burnSupply(
        address _investorAddress,
        uint256 _amount
    ) external;

    function setStaker(
        address _staker
    ) external;

    function resetStaker(
        address _staker
    ) external;

    function updateStakedToken(
        uint256 _stakedToken
    ) external;

    function updateMedTermShares(
        uint256 _shares
    ) external;

    function getTransFeeReward(
        uint256 _fromDay,
        uint256 _toDay
    )external view returns (uint256 rewardAmount);
    
    function getReservoirReward(
        uint256 _fromDay,
        uint256 _toDay
    )external view returns (uint256 rewardAmount);

    function getTokenHolderReward(
        uint256 _fromDay,
        uint256 _toDay
    )external view returns (uint256 rewardAmount);
}
