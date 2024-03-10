pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BalanceChecker {
    function balances(address[] calldata _users, address[] calldata _tokens) external view returns (uint256[] memory) {
        uint256[] memory addrBalances = new uint256[](_tokens.length * _users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 j = 0; j < _tokens.length; j++) {
                uint256 addrIdx = j + _tokens.length * i;
                if (_tokens[j] != address(0x0000000000000000000000000000000000000000)) {
                    addrBalances[addrIdx] = IERC20(_tokens[j]).balanceOf(_users[i]);
                } else {
                    addrBalances[addrIdx] = address(_users[i]).balance;
                }
            }
        }

        return addrBalances;
    }

    fallback() external payable {
        revert("This contract does not accept ethers");
    }
}

