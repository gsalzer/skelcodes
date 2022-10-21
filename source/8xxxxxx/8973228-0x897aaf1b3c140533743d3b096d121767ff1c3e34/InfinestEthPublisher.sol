pragma solidity ^0.5.11;

import "./SafeMath.sol";

contract InfinestEthPublisher
{
    using SafeMath for uint256;

    address public _owner;
    mapping(address => bool) public _approved;

    uint256 balance = 0;

    event Drop(address payable[] _toList, uint256[] _amountList);

    constructor() public
    {
        _owner = msg.sender;
        _approved[_owner] = true;
    }

    function () payable external
    {
        balance = balance.add(msg.value);
    }

    function getBalance() view external returns(uint256)
    {
        return balance;
    }

    function approve(address _target) external
    {
        require(msg.sender == _owner, 'unauthorized');
        _approved[_target] = true;
    }

    function reject(address _target) external
    {
        require(msg.sender == _owner, 'unauthorized');
        _approved[_target] = false;
    }

    function isApproved(address _target) view external returns(bool)
    {
        return _approved[_target];
    }

    function withdraw(uint256 value) external
    {
        require(balance >= value, 'not enough');
        require(msg.sender == _owner, 'unauthorized');
        msg.sender.transfer(value);
    }

    function drop(address payable[] calldata _toList, uint256[] calldata _amountList) external
    {
        require(_approved[msg.sender], 'unauthorized');
        require(_toList.length == _amountList.length, 'Not valid list length');

        uint256 sumOfBalances = 0;
        for(uint256 i=0; i<_amountList.length; i++)
        {
            sumOfBalances = sumOfBalances.add(_amountList[i]);
        }

        require(balance >= sumOfBalances, 'not enough');

        for(uint256 i=0; i<_toList.length; i++)
        {
            _toList[i].transfer(_amountList[i]);
        }

        emit Drop(_toList, _amountList);
    }
}
