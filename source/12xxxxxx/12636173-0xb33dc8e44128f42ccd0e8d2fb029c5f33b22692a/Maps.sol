pragma solidity ^0.6.0;
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

library Maps {
    using SafeMath for uint256;

    struct Participant {
        address Address;
        uint256 Participation;
        uint256 Tokens;
        uint256 Timestamp;
    }

    struct Map {
        mapping(uint => Participant) data;
        uint count;
        uint lastIndex;
        mapping(address => bool) addresses;
        mapping(address => uint) indexes;
    }

    function insertOrUpdate(Map storage self, Participant memory value) internal {
        if(!self.addresses[value.Address]) {
            uint newIndex = ++self.lastIndex;
            self.count++;
            self.indexes[value.Address] = newIndex;
            self.addresses[value.Address] = true;
            self.data[newIndex] = value;
        }
        else {
            uint existingIndex = self.indexes[value.Address];
            self.data[existingIndex] = value;
        }
    }

    function remove(Map storage self, Participant storage value) internal returns (bool success) {
        if(!self.addresses[value.Address]) {
            return false;
        }
        uint index = self.indexes[value.Address];
        self.addresses[value.Address] = false;
        self.indexes[value.Address] = 0;
        delete self.data[index];
        self.count--;
        return true;
    }

    function destroy(Map storage self) internal {
        for (uint i; i <= self.lastIndex; i++) {
            if(self.data[i].Address != address(0x0)) {
                delete self.addresses[self.data[i].Address];
                delete self.indexes[self.data[i].Address];
                delete self.data[i];
            }
        }
        self.count = 0;
        self.lastIndex = 0;
        return ;
    }
    
    function contains(Map storage self, Participant memory participant) internal view returns (bool exists) {
        return self.indexes[participant.Address] > 0;
    }

    function length(Map memory self) internal pure returns (uint) {
        return self.count;
    }

    function get(Map storage self, uint index) internal view returns (Participant storage) {
        return self.data[index];
    }

    function getIndexOf(Map storage self, address _address) internal view returns (uint256) {
        return self.indexes[_address];
    }

    function getByAddress(Map storage self, address _address) internal view returns (Participant storage) {
        uint index = self.indexes[_address];
        return self.data[index];
    }

    function containsAddress(Map storage self, address _address) internal view returns (bool exists) {
        return self.indexes[_address] > 0;
    }
}
