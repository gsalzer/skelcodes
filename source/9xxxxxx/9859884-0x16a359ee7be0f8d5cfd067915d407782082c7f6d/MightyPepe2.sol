pragma solidity 0.5.17;

contract MightyPepe2 {

    address payable public owner;
    uint256[6] public RankPrize;
    
    // Player struct
    struct PlayerStruct {
        address addr;
        uint256 rank;  // 0: no rank, 1: Pepe, 2: Advanced Pepe, 3: Mighty Pepe, 4: PepeSmart, 5: PepeT3h1337
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

    // Constructor
    constructor() public payable {
        owner = msg.sender;
    }

    // Join game
    function joinGame() external payable {
        require(msg.sender == tx.origin, "No contracts allowed");
        require(players[msg.sender].addr == address(0), "Player already exists");
        players[msg.sender] = PlayerStruct(msg.sender, 0);
    }

    // Be special
    function IamPepe(bytes memory _code) public payable isMember {
        players[msg.sender].rank = 0;
        uint256 leet_seed = 0x1337;
        address payable deployAddress = DeployCreate2Contract(0, _code, leet_seed);  // Yes, the seed is fixed

        // Are you special?
        bool isSpecial = ((uint256(deployAddress) % leet_seed) == (uint256(msg.sender) % leet_seed));

        if (isSpecial) {
            players[msg.sender].rank = 1;  // You are Pepe
            tinyPepe tpepe = tinyPepe(deployAddress);
            uint256 question = uint256(blockhash(block.number - 1));
            uint256 tpepeAnswer = tpepe.ask(question);
            // Be more special
            if (tpepeAnswer == (question % leet_seed)) {
                players[msg.sender].rank = 2;  // You are Advanced Pepe
                uint256 bytecodesize;
                assembly {
                  bytecodesize := extcodesize(deployAddress)
                }
                // Be the most special
                if (bytecodesize < 15) {
                    players[msg.sender].rank = 5;  // You are PepeT3h1337
                } else if (bytecodesize < 25) {
                    players[msg.sender].rank = 4;  // You are PepeSmart
                } else if (bytecodesize < 75) {
                    players[msg.sender].rank = 3;  // You are Mighty Pepe
                }
            }
        }
    }

    // Withdraw
    function withdraw() external payable isMember {
        require(players[msg.sender].rank > 2, "Pepe sad :'-(");
        uint256 winAmount;
        for (uint256 r = 3; r <= players[msg.sender].rank; r++) {
            winAmount += RankPrize[r];
            RankPrize[r] = 0;
        }
        require(winAmount > 0, "Prize(s) already claimed");
        msg.sender.transfer(winAmount);
    }

    // Internal functions
    function DeployCreate2Contract(uint256 _value, bytes memory _bytecode, uint256 _seed) internal returns (address payable) {
        address payable contractAddress;
        assembly {
            contractAddress := create2(_value, add(_bytecode, 0x20), mload(_bytecode), _seed)
        }
        return contractAddress;
    }

    // Other functions
    function depositPrize(uint256 rank) external payable {
        require((rank > 2) && (rank < RankPrize.length), "Rank min/max: 3 / 5");
        RankPrize[rank] += msg.value;
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
