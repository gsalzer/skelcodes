pragma solidity ^0.4.23;


contract IPClaim {

    /**
    * @param _type uint8, This number is a unique ID. Every ID shows the type of every IPClaim as it follows:
    *
    * id_0 = Invention
    * id_1 = Media / Image
    * id_2 = Media / 3D Art
    * id_3 = Media / Design
    * id_4 = Document / Literary work
    * id_5 = Document / Code
    * id_6 = Research
    * id_7 = Trademark / Word
    * id_8 = Trademark / Figurative
    * id_9 = Trademark / Figurative with words
    * id_10 = Trademark / Shape
    * id_11 = Trademark / Shape with words
    * id_12 = Trademark / Sound
    * id_13 = File
    */

    address public owner;
    uint256 public dateCreated;
    bytes32 public privateIPFSAddress;
    bytes32 public publicIPFSAddress;
    uint32 public id;
    address public registry;
    address public factory;
    uint8 public claimType;
    bool public isPublic;

    modifier onlyRegistry() {
        require(msg.sender == registry);
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory);
        _;
    }

    constructor(address _owner, bytes32 _privateIPFSAddress, bytes32 _publicIPFSAddress, uint8 _claimType,
        bool _isPublic, address _registry, address _factory) public {

        owner = _owner;
        privateIPFSAddress = _privateIPFSAddress;
        publicIPFSAddress = _publicIPFSAddress;
        claimType = _claimType;
        isPublic = _isPublic;
        registry = _registry;
        factory = _factory;
        dateCreated = now;
    }

    function setId(uint32 _id) public onlyRegistry {
        id = _id;
    }

    function changeOwner(address _owner) public onlyRegistry {
        require(_owner != address(0));
        owner = _owner;
    }

    function setToPublic(bytes32 _publicIPFSHash) public onlyFactory {
        isPublic = true;
        publicIPFSAddress = _publicIPFSHash;
    }

}
