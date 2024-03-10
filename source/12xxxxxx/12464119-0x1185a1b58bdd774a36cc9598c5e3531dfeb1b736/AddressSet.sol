pragma solidity ^0.5.13;

library AddressSet
{
    struct addrset
    {
        mapping(address => uint) index;
        address[] elements;
    }

    function insert(addrset storage self, address e)
        internal
        returns (bool success)
    {
        if (self.index[e] > 0) {
            return false;
        } else {
            self.index[e] = self.elements.push(e);
            return true;
        }
    }

    function remove(addrset storage self, address e)
        internal
        returns (bool success)
    {
        uint index = self.index[e];
        if (index == 0) {
            return false;
        } else {
            address e0 = self.elements[self.elements.length - 1];
            self.elements[index - 1] = e0;
            self.elements.pop();
            self.index[e0] = index;
            delete self.index[e];
            return true;
        }
    }

    function has(addrset storage self, address e)
        internal
        view
        returns (bool)
    {
        return self.index[e] > 0;
    }
}

