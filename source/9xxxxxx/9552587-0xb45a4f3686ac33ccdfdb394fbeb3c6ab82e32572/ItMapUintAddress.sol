pragma solidity ^0.4.24;

library ItMapUintAddress
{
    struct MapUintAddress
    {
        mapping(uint => MapValue) data;
        KeyFlag[] keys;
        uint size;
    }

    struct MapValue { uint keyIndex; address value; }

    struct KeyFlag { uint key; bool deleted; }

    function add(MapUintAddress storage self, uint key, address value) public returns (bool replaced)
    {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else
        {
            self.keys.push(KeyFlag(key, false));
            self.data[key].keyIndex = self.keys.length;
            self.size++;
            return false;
        }
    }

    function remove(MapUintAddress storage self, uint key) public returns (bool success)
    {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function contain(MapUintAddress storage self, uint key) public view returns (bool)
    {
        return self.data[key].keyIndex > 0;
    }

    function startIndex(MapUintAddress storage self) public view returns (uint keyIndex)
    {
        return nextIndex(self, uint(-1));
    }

    function validIndex(MapUintAddress storage self, uint keyIndex) public view returns (bool)
    {
        return keyIndex < self.keys.length;
    }

    function nextIndex(MapUintAddress storage self, uint _keyIndex) public view returns (uint)
    {
        uint keyIndex = _keyIndex;
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function getByIndex(MapUintAddress storage self, uint keyIndex) public view returns (address value)
    {
        uint key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function getByKey(MapUintAddress storage self, uint key) public view returns (address value) {
        return self.data[key].value;
    }
}
