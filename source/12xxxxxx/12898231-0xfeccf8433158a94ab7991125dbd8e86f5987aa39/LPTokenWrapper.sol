// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;


import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./IUniswapV2Pair.sol";

/**
 * @dev this contract forked from
 * https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
 *
*/
contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Pair public lptoken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor (IUniswapV2Pair token) {
        lptoken = token;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) virtual public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lptoken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) virtual public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lptoken.transfer(msg.sender, amount);
    }
}

