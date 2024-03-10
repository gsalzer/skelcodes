pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Registry is Ownable {
    struct Entry {
        bytes32 project;
        address proxyAddress;
    }

    Entry[] entries;

    event NewEntry(bytes32 indexed _project, address indexed _proxyAddress);
    event DeleteEntry(bytes32 indexed _project, address indexed _proxyAddress);
    event UpdateEntry(bytes32 indexed _project, address indexed _proxyAddress);

    function addEntry(bytes32 _project, address _proxyAddress) external onlyOwner {
        require(_proxyAddress != address(0));

        entries.push(Entry({
            project: _project,
            proxyAddress: _proxyAddress
        }));

        emit NewEntry(_project, _proxyAddress);
    }

    function deleteEntry(uint256 index) external onlyOwner {
        require(index < entries.length);

        emit DeleteEntry(entries[index].project, entries[index].proxyAddress);
        entries[index] = entries[entries.length - 1];
        entries.length--;
    }

    function updateEntryProject(uint256 index, bytes32 _project) external onlyOwner {
        require(index < entries.length);

        entries[index].project = _project;
        emit UpdateEntry(_project, entries[index].proxyAddress);
    }

    function updateEntryAddress(uint256 index, address _proxyAddress) external onlyOwner {
        require(index < entries.length);

        entries[index].proxyAddress = _proxyAddress;
        emit UpdateEntry(entries[index].project, _proxyAddress);
    }

    function getNumEntries() external view returns(uint256) {
        return entries.length;
    }

    function getEntries() external view returns(Entry[] memory) {
        return entries;
    }
}
