pragma solidity 0.5.17;

import "./ERC721Full.sol";
import "./Ownable.sol";

//NFT Contract


contract Rabbits is ERC721Full, Ownable {
    // All 160 Rabbits got color White, Blue and Red
    mapping(uint256 => string) public colorRabbit;

    // Only gameAddress can burn Rabbits
    address public gameControllerAddress;
    // Only farming can mint Rabbits
    address public farmControllerAddress;

    constructor() public ERC721Full("RabbitsToken", "RBTS") {
        // Rabbits Colors init

        // id 1 to 10 (10 Rabbits) are "White Rabbits"
        for (uint256 i = 1; i < 11; i++) {
            colorRabbit[i] = "White";
        }

        // id 11 to 60 (50 Rabbits) are "Blue Rabbits"
        for (uint256 i = 11; i < 61; i++) {
            colorRabbit[i] = "Blue";
        }

        // id 61 to 160 (100 Rabbits) are "Red Rabbits"
        for (uint256 i = 61; i < 161; i++) {
            colorRabbit[i] = "Red";
        }
    }

    modifier onlyGameController() {
        require(msg.sender == gameControllerAddress);
        _;
    }
    
    modifier onlyFarmingController() {
        require(msg.sender == farmControllerAddress);
        _;
    }

    // events for prevent Players from any change
    event GameAddressChanged(address newGameAddress);
    
    // events for prevent Players from any change
    event FarmAddressChanged(address newFarmAddress);
    

    // init game smart contract address
    function setGameAddress(address _gameAddress) public onlyOwner() {
        gameControllerAddress = _gameAddress;
        emit GameAddressChanged(_gameAddress);
    }
    
        // init farming smart contract address
    function setFarmingAddress(address _farmAddress) public onlyOwner() {
        farmControllerAddress = _farmAddress;
        emit FarmAddressChanged(_farmAddress);
    }

    // Function that only farming smart contract address can call for mint a Rabbit
    function mintRabbit(address _to, uint256 _id) public onlyFarmingController() {
        _mint(_to, _id);
    }

    // Function that only game smart contract address can call for burn Rabbits trilogy
    // Rabbits must be approvedForAll by the owner for contract of gameAddress
    function burnRabbitsTrilogy(
        address _ownerOfRabbit,
        uint256 _id1,
        uint256 _id2,
        uint256 _id3
    ) public onlyGameController() {
        require(
            keccak256(abi.encodePacked(colorRabbit[_id1])) ==
                keccak256(abi.encodePacked("White")) &&
                keccak256(abi.encodePacked(colorRabbit[_id2])) ==
                keccak256(abi.encodePacked("Blue")) &&
                keccak256(abi.encodePacked(colorRabbit[_id3])) ==
                keccak256(abi.encodePacked("Red"))
        );
        _burn(_ownerOfRabbit, _id1);
        _burn(_ownerOfRabbit, _id2);
        _burn(_ownerOfRabbit, _id3);
    }
}

