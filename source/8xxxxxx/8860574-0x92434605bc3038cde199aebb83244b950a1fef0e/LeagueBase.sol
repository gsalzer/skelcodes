pragma solidity ^0.5.0;

contract LeagueBase {
    
    struct Player {
        address self;
        address parent;
        uint bonus;
        uint totalBonus;
        uint invest;
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

    event logRandom(uint random, uint timestamp);

    event logLucky(address indexed target, uint money, uint timestamp, uint types);

    event logUserInvest(address indexed playerAddress, address indexed parentAddress, bool firstFlag, uint money, uint timestamp);

    event logWithDraw(address indexed playerAddress, uint money, uint timestamp);

    event logGlory(address indexed playerAddress, uint money, uint timestamp);

    event logFomo(address indexed target, uint money);
}
