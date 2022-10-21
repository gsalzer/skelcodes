pragma solidity ^0.5.0;

//note create a proper PToken interface

interface IPToken {
    event Redeem(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event MintOnDeposit(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event BurnOnLiquidation(
        address indexed _from,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event BalanceTransfer(
        address indexed _from,
        address indexed _to,
        uint256 _value,
        uint256 _fromBalanceIncrease,
        uint256 _toBalanceIncrease,
        uint256 _fromIndex,
        uint256 _toIndex
    );
    event InterestStreamRedirected(
        address indexed _from,
        address indexed _to,
        uint256 _redirectedBalance,
        uint256 _fromBalanceIncrease,
        uint256 _fromIndex
    );
    event RedirectedBalanceUpdated(
        address indexed _targetAddress,
        uint256 _targetBalanceIncrease,
        uint256 _targetIndex,
        uint256 _redirectedBalanceAdded,
        uint256 _redirectedBalanceRemoved
    );
    event InterestRedirectionAllowanceChanged(
        address indexed _from,
        address indexed _to
    );

    function balanceOf(address _user) external view returns (uint256);
}

