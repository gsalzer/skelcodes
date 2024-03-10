pragma solidity ^0.5.10;

import "./Ownable.sol";
import "./Farm.sol";

contract Pigpen is Ownable {
    using Farm for Farm.Pigpen;

    // pigpen
    Farm.Pigpen private pigpen;

    // Pigpen events
    event JoinPigpen(address indexed _address, uint256 _balance, uint256 _prevSize);
    event LeavePigpen(address indexed _address, uint256 _balance, uint256 _prevSize);

    uint256 public constant TOP_SIZE = 100;

    constructor() public {
        pigpen.initialize();
    }

    function topSize() external pure returns (uint256) {
        return TOP_SIZE;
    }

    function addressAt(uint256 _i) external view returns (address addr) {
        (addr, ) = pigpen.entry(_i);
    }

    function indexOf(address _addr) external view returns (uint256) {
        return pigpen.index[_addr];
    }

    function entry(uint256 _i) external view returns (address, uint256) {
        return pigpen.entry(_i);
    }

    function top() external view returns (address, uint256) {
        return pigpen.top();
    }

    function size() external view returns (uint256) {
        return pigpen.size();
    }

    function update(address _addr, uint256 _new) external onlyOwner {
        uint256 _size = pigpen.size();

        // If the pigpen is empty
        // join the _addr
        if (_size == 0) {
            emit JoinPigpen(_addr, _new, 0);
            pigpen.insert(_addr, _new);
            return;
        }

        // Load top value of the pigpen
        (, uint256 lastBal) = pigpen.top();

        // If our target address already is in the pigpen
        if (pigpen.has(_addr)) {
            // Update the target address value
            pigpen.update(_addr, _new);
            // If the new value is 0
            // always pop the pigpen
            // we updated the pigpen, so our address should be on top
            if (_new == 0) {
                pigpen.popTop();
                emit LeavePigpen(_addr, 0, _size);
            }
        } else {
            // IF pigpen is full or new balance is higher than pop pigpen
            if (_new != 0 && (_size < TOP_SIZE || lastBal < _new)) {
                // If pigpen is full pop pigpen
                if (_size >= TOP_SIZE) {
                    (address _poped, uint256 _balance) = pigpen.popTop();
                    emit LeavePigpen(_poped, _balance, _size);
                }

                // Insert new value
                pigpen.insert(_addr, _new);
                emit JoinPigpen(_addr, _new, _size);
            }
        }
    }
}

