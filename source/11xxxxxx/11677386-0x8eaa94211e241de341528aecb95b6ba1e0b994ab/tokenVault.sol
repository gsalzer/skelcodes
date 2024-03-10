// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./SafeERC20.sol";

contract tokenVault {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    ERC20 public token;
    
    address owner_address;
    address timelock_address;

    uint PERIOD = 2 days;
    uint public withdrawTime;
    uint public withdrawNum;


    modifier onlyByOwnerOrGovernance() {
        require(msg.sender == owner_address || msg.sender == timelock_address, "You are not an owner or the governance timelock");
        _;
    }

    constructor(address _token) public {
        token = ERC20(_token);

        owner_address = msg.sender;
        timelock_address = msg.sender;
    }

    function setOwner(address _owner_address) external onlyByOwnerOrGovernance {
        owner_address = _owner_address;
    }
    
    function setPeriod(uint _period) external onlyByOwnerOrGovernance {
        require(_period >= 2 days);
        PERIOD = _period;
    }
    
    function setToken(address _token) external onlyByOwnerOrGovernance {
        token = ERC20(_token);
    }

    function setTimelock(address _timelock_address) external onlyByOwnerOrGovernance {
        timelock_address = _timelock_address;
    }

    function request(uint _amount) external onlyByOwnerOrGovernance {
        withdrawTime = block.timestamp.add(PERIOD);
        withdrawNum = _amount;
    }
    
    function withdraw() external onlyByOwnerOrGovernance {
        require(block.timestamp >= withdrawTime, "It's not time yet.");
        token.safeTransfer(msg.sender, withdrawNum);
        withdrawNum = 0;
    }
}

