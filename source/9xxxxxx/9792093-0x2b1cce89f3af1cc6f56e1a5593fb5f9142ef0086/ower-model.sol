pragma solidity ^0.4.17;

contract OwerModel {
    struct Abstract {
        uint timestamp;
        address sender;
        uint version;
        bytes32 hash;
        byte[512] extend;
    }
    mapping(bytes32 => Abstract) abstractData;
    mapping(address => bool) public allowedMap;
    address[] public allowedArray;

    event AddressAllowed(address _handler, address _address);
    event AddressDenied(address _handler, address _address);
    event DataSaved(address indexed _handler, uint timestamp, address indexed sender, uint version, bytes32 hash);
    event ExtendSaved(address indexed _handler, byte[512] extend);
    event ExtendNotSave(address indexed _handler, uint version, byte[512] extend);

    function DataModel() public {
        allowedMap[msg.sender] = true;
        allowedArray.push(msg.sender);
    }

    modifier allow() {
        require(allowedMap[msg.sender] == true);
        _;
    }

    function allowAccess(address _address) allow public {
        allowedMap[_address] = true;
        allowedArray.push(_address);
        AddressAllowed(msg.sender, _address);
    }

    function denyAccess(address _address) allow public {
        allowedMap[_address] = false;
        AddressDenied(msg.sender, _address);
    }

    function getData(bytes32 _key) public view returns(uint, address, uint, bytes32, byte[512]) {
        return (
            abstractData[_key].timestamp,
            abstractData[_key].sender,
            abstractData[_key].version,
            abstractData[_key].hash,
            abstractData[_key].extend
        );
    }

    function setData(bytes32 _key, uint timestamp, address sender, uint version, bytes32 hash) allow public {
        abstractData[_key].timestamp = timestamp;
        abstractData[_key].sender = sender;
        abstractData[_key].version = version;
        abstractData[_key].hash = hash;
        DataSaved(msg.sender, timestamp, sender, version, hash);
    }

    function setExtend(bytes32 _key, byte[512] extend) allow public {
        if (abstractData[_key].version > 0) {
            for (uint256 i; i < 512; i++) {
                abstractData[_key].extend[i] = extend[i];
            }
            ExtendSaved(msg.sender, extend);
        } else {
            ExtendNotSave(msg.sender, abstractData[_key].version, extend);
        }
    }
}
