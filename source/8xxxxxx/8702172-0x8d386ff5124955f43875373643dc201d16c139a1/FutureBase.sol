pragma solidity ^0.5.0;

contract FutureBase {
    
    struct Player {
        address self;
        address parent;
        uint256 bonus;
        uint256 totalBonus;
        uint256 invest;
        uint sons;
        uint round;
        uint index;
    }

    struct Investment {
        address self;
        uint amount;
        uint time;
        uint round;
        bool firstFlag;
    }

    event logRandom(uint256 random, uint timestamp);

    event logLucky(address indexed target, uint256 money, uint timestamp, uint types);

    event logUserInvest(address indexed playerAddress, address indexed parentAddress, bool firstFlag, uint256 money, uint timestamp);

    event logWithDraw(address indexed playerAddress, uint256 money, uint timestamp);

    event logFomo(address indexed target, uint256 money);
}

