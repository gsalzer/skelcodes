// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

interface IBalanceOf {
    function balanceOf(address _owner) external returns (uint256 _balance);
}

contract MultiBalanceCaller {
    function multiBalanceOf(address[] calldata _tokens, address _owner) public returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            balances[i] = IBalanceOf(_tokens[i]).balanceOf(_owner);
        }
        return balances;
    }
}
