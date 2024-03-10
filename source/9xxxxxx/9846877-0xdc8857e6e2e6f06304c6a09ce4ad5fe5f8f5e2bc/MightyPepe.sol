pragma solidity 0.5.17;

contract MightyPepe {

    address payable public owner;

    // Player struct
    struct PlayerStruct {
        address addr;
        uint256 rank;   // 0 - no rank, 1 - Pepe, 2 - advanced Pepe, 3 - Mighty Pepe (withdrawable)
    }
    // Player mapping
    mapping(address => PlayerStruct) public players;

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    modifier isMember() {
        require(players[msg.sender].addr != address(0), "Only member can play");
        _;
    }

    modifier isMightyPepe() {
        require(players[msg.sender].rank == 3, "Pepe sad :'-(");
        _;
    }

    // Constructor
    constructor() public payable {
        owner = msg.sender;
    }

    // Join game
    function joinGame() external payable {
        require(players[msg.sender].addr == address(0), "Player already exists");
        players[msg.sender] = PlayerStruct(msg.sender, 0);
    }

    // Be special
    function IamPepe(bytes memory _code) public payable isMember {
        players[msg.sender].rank = 0;
        uint256 leet_seed = 0x1337;
        address payable deployAddress = DeployCreate2Contract(_code, bytes32(leet_seed), 0);  // Yes, the seed is fixed

        // Are you special?
        bool isSpecial = ((uint256(deployAddress) % leet_seed) == (uint256(msg.sender) % leet_seed));

        if (isSpecial) {
            players[msg.sender].rank = 1;  // You are Pepe
            uint256 bytecodesize;
            assembly {
              bytecodesize := extcodesize(deployAddress)
            }
            // Be more special
            if (bytecodesize < 100) {
                players[msg.sender].rank = 2;  // You are advanced Pepe
                tinyPepe tpepe = tinyPepe(deployAddress);
                uint256 tpepeAnswer;
                uint256 question = uint256(blockhash(block.number - 1));
                tpepeAnswer = tpepe.ask(question);
                // Be the most special
                if (tpepeAnswer == (question % leet_seed)) {
                    players[msg.sender].rank = 3;  // You are Mighty Pepe
                }
            }
        }
    }

    // Withdraw
    function withdraw() external payable isMember isMightyPepe {
        msg.sender.transfer(address(this).balance);
    }

    // Internal functions
    function DeployCreate2Contract(bytes memory bytecode, bytes32 seed, uint256 value) internal returns (address payable) {
        address payable contractAddress;
        assembly {
            contractAddress := create2(value, add(bytecode, 0x20), mload(bytecode), seed)
        }
        return contractAddress;
    }

    // Standard functions
    function withdrawOwner() external payable onlyOwner {
        owner.transfer(address(this).balance);
    }

    function kill() external payable onlyOwner {
        selfdestruct(owner);
    }

    // Fallback
    function() external payable { }
}

contract tinyPepe {

    function ask(uint256 question) public pure returns (uint256) {
        uint256 answer = question % 0x1337;
        return answer;
    }
}
