// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IEIP2612.sol";

contract StakingRewards is ReentrancyGuard {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) private stakingTokenMap;
    mapping(address => uint256) private _totalSupply;
    mapping(address => mapping(address => uint256)) private _balances;
    address[] private stakingTokenArray;
    
    event Staked(address indexed user,address indexed token, uint256 amount);
    event Withdrawn(address indexed user,address indexed token, uint256 amount);
    
    constructor(address[] memory _stakingToken) {
        for(uint i = 0 ; i < _stakingToken.length; i++){
           stakingTokenMap[_stakingToken[i]] = true;
        }
        stakingTokenArray = _stakingToken;
    }
    
    function totalSupply(address token) external view returns (uint256) { 
        return _totalSupply[token];
    }
 
    function balanceOf(address account,address token) external view returns (uint256) {
        return _balances[account][token];
    }
    
    function getStakingTokens() external view returns (address[] memory) {
        return stakingTokenArray;
    }
    
    
    function stakeWithPermit(address _stakingToken,uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external nonReentrant {
        require(amount > 0, "cannot stake 0");
        require(stakingTokenMap[_stakingToken] == true,"cannot support!");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].add(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].add(amount);

        // permit
        IEIP2612(_stakingToken).permit(msg.sender, address(this), amount, deadline, v, r, s);

        IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender,_stakingToken, amount);
    }
    
    function stake(address _stakingToken,uint256 amount) external nonReentrant {
        require(amount > 0, "cannot stake 0");
        require(stakingTokenMap[_stakingToken] == true,"cannot support!");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].add(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].add(amount);
        IERC20(_stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender,_stakingToken,amount);
    }

    function withdraw(address _stakingToken,uint256 amount) public nonReentrant {
        require(amount > 0, "cannot withdraw 0");
        require(stakingTokenMap[_stakingToken] == true,"cannot support!");
        require(_balances[msg.sender][_stakingToken] >= amount,"cannot withdraw!");
        _totalSupply[_stakingToken] = _totalSupply[_stakingToken].sub(amount);
        _balances[msg.sender][_stakingToken] = _balances[msg.sender][_stakingToken].sub(amount);
        IERC20(_stakingToken).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender,_stakingToken,amount);
    }
}
