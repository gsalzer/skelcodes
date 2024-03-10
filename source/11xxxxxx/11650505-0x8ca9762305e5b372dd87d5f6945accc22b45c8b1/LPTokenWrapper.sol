pragma solidity ^0.6.0;

import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address internal team = 0x3a0910E373aa1845E439f7009326A17F4b612965; 
    address internal government = 0x4C0b98cF1761425A6a23a16cC1bD5c51C1638703; 
    address internal insurance  = 0xaa5de6aD842b4eB26b85511e3f4A85DAFBd5fD68; 

    IERC20 public lpt;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event InvitationReward(address indexed user, uint8 indexed lv, uint256 amount);

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        lpt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        lpt.safeTransfer(msg.sender, amount.mul(97).div(100)); //97%
        lpt.safeTransfer(team, amount.mul(3).div(100));   //3%
    }

}
