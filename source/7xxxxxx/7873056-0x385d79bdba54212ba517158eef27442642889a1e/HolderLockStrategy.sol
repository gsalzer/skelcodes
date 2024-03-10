pragma solidity >=0.4.25 <0.6.0;

import './SafeMath.sol';
import './ERC20.sol';

contract HolderLockStrategy {
    using SafeMath for uint256;
    string public name;
    uint256 private _lockedBalance;
    address private _lockedAddress;
    address private _admin;
    uint[] private _unlockDates;
    uint[] private _unlockPercents;
    bool private _initialized;
    address private _token;
    uint private _withdrawed;

    // unlockPercent_: 0 - 100的整数
    function init(string memory title, uint[] memory unlockDates,
                uint[] memory unlockPercents, address lockedAddress, uint lockedBalance, address token) internal {
        require(!_initialized);
        _initialized = true;
        name = title;
        require(unlockDates.length == unlockPercents.length);
        
        for (uint i = 0; i < unlockPercents.length; ++i) {
            _unlockDates.push(unlockDates[i]);
            _unlockPercents.push(unlockPercents[i]);
        }
        
        _lockedAddress = lockedAddress;
        _lockedBalance = lockedBalance;
        _token = token;

        _admin = msg.sender;
    }

    function getDate() private
        view
        returns (uint256) {
        return now;
    }

    function calculatePhase() public view returns (uint256) {
        uint idx = 0;
        uint today = getDate();
        for (; idx < _unlockDates.length; ++idx) {
            if (today < _unlockDates[idx])  break;
        } 

        return idx;
    }

    function calculateUnlockedAmount() public view returns (uint256) {
        uint idx = calculatePhase();

        if (idx == 0) {
            return 0;
        } else if (idx >= _unlockDates.length) {
            return _lockedBalance;
        } else {
            uint unlock = _unlockPercents[idx - 1];
            if (unlock > 100) 
                unlock = 100;
            return _lockedBalance.mul(unlock).div(100);
        }
    }

    function withdraw(address _to) public returns (bool) {
        require(msg.sender == _admin);
        uint256 available = availableBalance();
        if (available > 0) {
            ERC20 token = ERC20(_token);
            require(token.transfer(_to, available));
            _withdrawed = _withdrawed.add(available);
            return true;
        } else {
            return false;
        }
    }

    function availableBalance() public
        view 
        returns (uint256) {
        uint unlockable = calculateUnlockedAmount();
        return unlockable.sub(_withdrawed);
    }

    function checkBalance(address _holder) public view returns (uint256) {
        ERC20 token = ERC20(_token);
        return token.balanceOf(_holder);
    }
}
