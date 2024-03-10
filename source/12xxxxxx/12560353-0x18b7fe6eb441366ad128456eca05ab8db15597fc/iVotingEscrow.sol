pragma solidity ^0.7.4;
// "SPDX-License-Identifier: MIT"

interface iVotingEscrow {
    
    function create_lock_for_origin(uint256 _value, uint256 _unlock_time) external; 
      
}

