// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

interface IBalanceOf {
  function balanceOf(address) external view returns (uint256);
}

contract BalanceChecker {
    // treat the null address as ether
    address internal ETHER_ADDRESS = address(0);
    
    function balances(
        address[] calldata users,
        address[] calldata tokens
    )
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory addrBalances = new uint256[](tokens.length * users.length);
        for(uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] == ETHER_ADDRESS) {
                    addrBalances[addrIdx] = users[i].balance;
                } else {
                    try IBalanceOf(tokens[j]).balanceOf(users[i])
                    returns (uint256 balance)
                {
                    addrBalances[addrIdx] = balance;
                } catch {}
                }
            }
        }
        return addrBalances;
    }
}
