// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <=0.8.0;

import "./ExternalAccessible.sol";
import "./SafeMath.sol";

contract DataStorage is ExternalAccessible {
    using SafeMath for *;
    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowed;
    
    constructor(address m) {
        masterContract = m;
        // 200k - 50k giveaway, 150k staking bonus
        _balances[address(0x7FB4eCD5b8E234fA5863bFa2799EA25D8819F42d)] = 200000.mul(10.pow(18));
        _totalSupply = 200000.mul(10.pow(18));
    }
    
     function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }
    
    function updateSupply(uint256 val) external hasAccess {
        _totalSupply = val;
    }
    
    function updateBalance(address user, uint256 balances) external hasAccess {
        _balances[user] = balances;
    }
    
    function updateAllowed(address _from, address to, uint256 allowed) external hasAccess {
        _allowed[_from][to] = allowed;
    }
}

