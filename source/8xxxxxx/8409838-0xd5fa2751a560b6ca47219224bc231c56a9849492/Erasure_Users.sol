pragma solidity ^0.5.0;


library HitchensUnorderedAddressSetLib {

    struct Set {
        mapping(address => uint) keyPointers;
        address[] keyList;
    }

    function insert(Set storage self, address key) internal {
        require(key != address(0), "UnorderedKeySet(100) - Key cannot be 0x0");
        require(!exists(self, key), "UnorderedAddressSet(101) - Address (key) already exists in the set.");
        self.keyPointers[key] = self.keyList.push(key)-1;
    }

    function remove(Set storage self, address key) internal {
        require(exists(self, key), "UnorderedKeySet(102) - Address (key) does not exist in the set.");
        address keyToMove = self.keyList[count(self)-1];
        uint rowToReplace = self.keyPointers[key];
        self.keyPointers[keyToMove] = rowToReplace;
        self.keyList[rowToReplace] = keyToMove;
        delete self.keyPointers[key];
        self.keyList.length--;
    }

    function count(Set storage self) internal view returns(uint) {
        return(self.keyList.length);
    }

    function exists(Set storage self, address key) internal view returns(bool) {
        if(self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    function keyAtIndex(Set storage self, uint index) internal view returns(address) {
        return self.keyList[index];
    }

    function nukeSet(Set storage self) internal {
        delete self.keyList;
    }
}



contract Erasure_Users {

    using HitchensUnorderedAddressSetLib for HitchensUnorderedAddressSetLib.Set;
    HitchensUnorderedAddressSetLib.Set private _users;

    mapping (address => bytes) private _metadata;

    event UserRegistered(address indexed user, bytes data);
    event UserRemoved(address indexed user);

    // state functions

    function registerUser(bytes memory data) public {
        require(!_users.exists(msg.sender), "user already exists");

        // add user
        _users.insert(msg.sender);

        // set metadata
        _metadata[msg.sender] = data;

        // emit event
        emit UserRegistered(msg.sender, data);
    }

    function removeUser() public {
        // require user is registered
        require(_users.exists(msg.sender), "user does not exist");

        // remove user
        _users.remove(msg.sender);

        // delete metadata
        delete _metadata[msg.sender];

        // emit event
        emit UserRemoved(msg.sender);
    }

    // view functions

    function getUserData(address user) public view returns (bytes memory data) {
        data = _metadata[user];
    }

    function getUsers() public view returns (address[] memory users) {
        users = _users.keyList;
    }

    function getUserCount() public view returns (uint256 count) {
        count = _users.count();
    }

    // Note: startIndex is inclusive, endIndex exclusive
    function getPaginatedUsers(uint256 startIndex, uint256 endIndex) public view returns (address[] memory users) {
        require(startIndex < endIndex, "startIndex must be less than endIndex");
        require(endIndex <= _users.count(), "end index out of range");

        // initialize fixed size memory array
        address[] memory range = new address[](endIndex - startIndex);

        // Populate array with addresses in range
        for (uint256 i = startIndex; i < endIndex; i++) {
            range[i - startIndex] = _users.keyAtIndex(i);
        }

        // return array of addresses
        users = range;
    }
}

