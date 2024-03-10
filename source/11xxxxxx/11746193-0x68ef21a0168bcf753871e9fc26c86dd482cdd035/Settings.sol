pragma solidity ^0.6.2;

import './Ownable.sol';

contract Settings is Ownable {

  constructor() public {
  }
  
  
    struct Entry{
        uint index; // index start 1 to keyList.length
        address value;
    }
    
    mapping(bytes32 => Entry) internal map;
    bytes32[] internal keyList;

    function add(bytes32 _key, address _value) onlyOwner public {
        Entry storage entry = map[_key];
        entry.value = _value;
        if(entry.index > 0){ // entry exists
            // do nothing
            return;
        }else { // new entry
            keyList.push(_key);
            uint keyListIndex = keyList.length - 1;
            entry.index = keyListIndex + 1;
        }
    }

    function remove(bytes32 _key) onlyOwner public {
        Entry storage entry = map[_key];
        require(entry.index != 0); // entry not exist
        require(entry.index <= keyList.length); // invalid index value
        
        // Move an last element of array into the vacated key slot.
        uint keyListIndex = entry.index - 1;
        uint keyListLastIndex = keyList.length - 1;
        map[keyList[keyListLastIndex]].index = keyListIndex + 1;
        keyList[keyListIndex] = keyList[keyListLastIndex];
        keyList.pop();
        delete map[_key];
    }
    
    function size() public view returns (uint) {
        return uint(keyList.length);
    }
    
    function contains(bytes32 _key) public view returns (bool) {
        return map[_key].index > 0;
    }
    
    function getByKey(bytes32 _key) public view returns (address) {
        return map[_key].value;
    }
    
    function getByIndex(uint _index) public view returns (address) {
        require(_index >= 0);
        require(_index < keyList.length);
        return map[keyList[_index]].value;
    }

    function getKeys() public view returns ( bytes32[] memory) {
        return keyList;
    }

}
