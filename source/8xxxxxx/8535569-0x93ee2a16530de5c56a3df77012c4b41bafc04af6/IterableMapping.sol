pragma solidity ^0.5.8;
import "./SafeMath.sol";
library IterableMapping
{
    using SafeMath for uint;
    struct itmap
    {
        mapping(uint => IndexValue) data;
        KeyFlag[] keys;
        uint size;
    }
    struct IndexValue { uint keyIndex; uint value; }
    struct KeyFlag { uint key; bool deleted; }
    function insert(itmap storage self, uint key, uint value) public returns (bool replaced)
    {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else
        {
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }
    function add_or_insert(itmap storage self, uint key, uint value) public returns (bool added)
    {
        uint keyIndex = self.data[key].keyIndex;

        if (keyIndex > 0)
        {
            self.data[key].value = self.data[key].value.add(value);
            return true;
        }
        else
        {
            self.data[key].value = value;
            keyIndex = self.keys.length++;
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }
    function sub(itmap storage self, uint key, uint value) public returns (bool subbed)
    {
        uint keyIndex = self.data[key].keyIndex;

        if (keyIndex > 0)
        {
            self.data[key].value = self.data[key].value.sub(value);
            return true;
        }
        return false;
    }

    function remove(itmap storage self, uint key) public returns (bool success)
    {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }

    function clear(itmap storage self) public
    {
        uint len = self.keys.length;
        for(uint i = 0; i<len; i++)
        {
            if(!self.keys[i].deleted)
            {
                delete self.data[self.keys[i].key];
            }
        }
        self.keys.length = 0;
        self.size = 0;
    }
    function contains(itmap storage self, uint key) public view returns (bool)
    {
        return self.data[key].keyIndex > 0;
    }
    function iterate_start(itmap storage self) public view returns (uint keyIndex)
    {
        return iterate_next(self, uint(-1));
    }
    function iterate_valid(itmap storage self, uint keyIndex) public view returns (bool)
    {
        return keyIndex < self.keys.length;
    }
    function iterate_next(itmap storage self, uint keyIndex) public view returns (uint r_keyIndex)
    {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }
    function iterate_get(itmap storage self, uint keyIndex) public view returns (uint key, uint value)
    {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

