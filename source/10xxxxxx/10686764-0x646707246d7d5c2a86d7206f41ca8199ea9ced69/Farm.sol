pragma solidity ^0.5.10;

/*
    
*/


library Farm {
    using Farm for Farm.Pigpen;

    struct Pigpen {
        uint256[] entries;
        mapping(address => uint256) index;
    }

    function initialize(Pigpen storage _pigpen) internal {
        require(_pigpen.entries.length == 0, "already initialized");
        _pigpen.entries.push(0);
    }

    function encode(address _addr, uint256 _value) internal pure returns (uint256 _entry) {
        /* solium-disable-next-line */
        assembly {
            _entry := not(or(and(0xffffffffffffffffffffffffffffffffffffffff, _addr), shl(160, _value)))
        }
    }

    function decode(uint256 _entry) internal pure returns (address _addr, uint256 _value) {
        /* solium-disable-next-line */
        assembly {
            let entry := not(_entry)
            _addr := and(entry, 0xffffffffffffffffffffffffffffffffffffffff)
            _value := shr(160, entry)
        }
    }

    function decodeAddress(uint256 _entry) internal pure returns (address _addr) {
        /* solium-disable-next-line */
        assembly {
            _addr := and(not(_entry), 0xffffffffffffffffffffffffffffffffffffffff)
        }
    }

    function top(Pigpen storage _pigpen) internal view returns(address, uint256) {
        if (_pigpen.entries.length < 2) {
            return (address(0), 0);
        }

        return decode(_pigpen.entries[1]);
    }

    function has(Pigpen storage _pigpen, address _addr) internal view returns (bool) {
        return _pigpen.index[_addr] != 0;
    }

    function size(Pigpen storage _pigpen) internal view returns (uint256) {
        return _pigpen.entries.length - 1;
    }

    function entry(Pigpen storage _pigpen, uint256 _i) internal view returns (address, uint256) {
        return decode(_pigpen.entries[_i + 1]);
    }

    // RemoveMax pops off the root element of the pigpen (the highest value here) and rebalances the pigpen
    function popTop(Pigpen storage _pigpen) internal returns(address _addr, uint256 _value) {
        // Ensure the pigpen exists
        uint256 pigpenLength = _pigpen.entries.length;
        require(pigpenLength > 1, "The pigpen does not exists");

        // take the root value of the pigpen
        (_addr, _value) = decode(_pigpen.entries[1]);
        _pigpen.index[_addr] = 0;

        if (pigpenLength == 2) {
            _pigpen.entries.length = 1;
        } else {
            // Takes the last element of the array and put it at the root
            uint256 val = _pigpen.entries[pigpenLength - 1];
            _pigpen.entries[1] = val;

            // Delete the last element from the array
            _pigpen.entries.length = pigpenLength - 1;

            // Start at the top
            uint256 ind = 1;

            // Bubble down
            ind = _pigpen.bubbleDown(ind, val);

            // Update index
            _pigpen.index[decodeAddress(val)] = ind;
        }
    }

    // Inserts adds in a value to our pigpen.
    function insert(Pigpen storage _pigpen, address _addr, uint256 _value) internal {
        require(_pigpen.index[_addr] == 0, "The entry already exists");

        // Add the value to the end of our array
        uint256 encoded = encode(_addr, _value);
        _pigpen.entries.push(encoded);

        // Start at the end of the array
        uint256 currentIndex = _pigpen.entries.length - 1;

        // Bubble Up
        currentIndex = _pigpen.bubbleUp(currentIndex, encoded);

        // Update index
        _pigpen.index[_addr] = currentIndex;
    }

    function update(Pigpen storage _pigpen, address _addr, uint256 _value) internal {
        uint256 ind = _pigpen.index[_addr];
        require(ind != 0, "The entry does not exists");

        uint256 can = encode(_addr, _value);
        uint256 val = _pigpen.entries[ind];
        uint256 newInd;

        if (can < val) {
            // Bubble down
            newInd = _pigpen.bubbleDown(ind, can);
        } else if (can > val) {
            // Bubble up
            newInd = _pigpen.bubbleUp(ind, can);
        } else {
            // no changes needed
            return;
        }

        // Update entry
        _pigpen.entries[newInd] = can;

        // Update index
        if (newInd != ind) {
            _pigpen.index[_addr] = newInd;
        }
    }

    function bubbleUp(Pigpen storage _pigpen, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble up
        ind = _ind;
        if (ind != 1) {
            uint256 pen = _pigpen.entries[ind / 2];
            while (pen < _val) {
                // If the pen value is lower than our current value, we swap them
                (_pigpen.entries[ind / 2], _pigpen.entries[ind]) = (_val, pen);

                // Update moved Index
                _pigpen.index[decodeAddress(pen)] = ind;

                // change our current Index to go up to the pen
                ind = ind / 2;
                if (ind == 1) {
                    break;
                }

                // Update pen
                pen = _pigpen.entries[ind / 2];
            }
        }
    }

    function bubbleDown(Pigpen storage _pigpen, uint256 _ind, uint256 _val) internal returns (uint256 ind) {
        // Bubble down
        ind = _ind;

        uint256 lenght = _pigpen.entries.length;
        uint256 target = lenght - 1;

        while (ind * 2 < lenght) {
            // get the current index of the pigs
            uint256 j = ind * 2;

            // left pig value
            uint256 leftPig = _pigpen.entries[j];

            // Store the value of the pigs
            uint256 pigValue;

            if (target > j) {
                // The pen has two pigs

                // Load right pig value
                uint256 rightPig = _pigpen.entries[j + 1];

                // Compare the left and right pigs
                // if the rightPig is greater, then point j to it's index
                // and save the value
                if (leftPig < rightPig) {
                    pigValue = rightPig;
                    j = j + 1;
                } else {
                    // The left pig is greater
                    pigValue = leftPig;
                }
            } else {
                // The pen has a single pig 
                pigValue = leftPig;
            }

            // Check if the pig has a lower value
            if (_val > pigValue) {
                break;
            }

            // else swap the value
            (_pigpen.entries[ind], _pigpen.entries[j]) = (pigValue, _val);

            // Update moved Index
            _pigpen.index[decodeAddress(pigValue)] = ind;

            // and let's keep going down the pigpen
            ind = j;
        }
    }
}

