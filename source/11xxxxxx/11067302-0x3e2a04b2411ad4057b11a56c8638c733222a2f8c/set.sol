library AddressSet {
    
    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    function insert(Set storage self, address key) internal {
        if(exists(self, key)) return;        
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length-1;
    }

    function remove(Set storage self, address key) internal {
        if(!exists(self, key)) return;
        uint last = self.keyList.length - 1;
        uint rowToReplace = self.keyPointers[key];
        if(rowToReplace != last) {
            address keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }
    function getElementAt(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }
}
