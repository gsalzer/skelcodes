// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./uniswapv2/interfaces/IUniswapV2Pair.sol";

import "./utils/QueueStakesFuns.sol";
import "./interfaces/IStakeGatling.sol";
import "./interfaces/IMatchPair.sol";
import "./interfaces/IPriceSafeChecker.sol";


contract MatchPairStorage{

    uint256 safeProtect = 50;
    uint256 public constant PROXY_INDEX = 0;
    
    struct QueuePoolInfo {
        //LP Token : LIFO
        UserStake[] lpQueue;
        //from LP to priorityQueue :FIFO
        QueueStakes priorityQueue;
        //Single Token  : FIFO
        QueueStakes pendingQueue;
        //Queue Total
        uint256 totalPending;
        //index of User index
        mapping(address => uint256[]) userLP;
        mapping(address => uint256[]) userPriority;
        mapping(address => uint256[]) userPending;
    }
    //LP token Address
    IUniswapV2Pair public lpToken;
    //queue
    QueuePoolInfo  queueStake0;
    QueuePoolInfo  queueStake1;

    IStakeGatling public stakeGatling;
    IPriceSafeChecker public priceChecker;

    event Stake(bool _index0, address _user, uint256 _amount);

}

