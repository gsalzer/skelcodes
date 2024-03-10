// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";

contract BasePool {
    using SafeMath for uint256;

    /* 存款总量 */
    uint256 internal _totalSupply;

    /* 用户实时余额 */
    mapping(address => uint256) internal _balances;

    // 存款币
    IERC20 public depositToken;

    /* 奖励代币  */
    IERC20 public rewardToken;

    constructor() {}

    /**
     * @dev 总余额.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev 用户当前余额.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /* 获取转出代币数量 */
    function usedAmount() public view returns (uint256) {
        uint256 balance = depositToken.balanceOf(address(this));
        if (_totalSupply > balance) {
            return _totalSupply.sub(balance);
        } else {
            return 0;
        }
    }
}

