pragma solidity ^0.4.24;

contract LuckyDraw {
    address public admin;
    address[] private players;
    address private winner;

    constructor() public{
        admin = msg.sender;
        winner = address(0x0);
    }

    modifier onlyOwner() {
        require(msg.sender == admin, "Only Admin");
        _;
    }

    function random()
        private
        view
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, now, players.length)));
    }

    function add(address _plyrAddr)
        public
    {
        players.push(_plyrAddr);
    }

    function draw()
        public
        returns (address)
    {
        winner =  players[random() % players.length];
        players = new address[](0);
        return winner;
    }

    function getPlayers()
        public
        view
        returns(address[])
    {
        return players;
    }
    function getPlayersCount()
        public
        view
        returns(uint256)
    {
        return players.length;
    }
    function getWinner()
        public
        view
        returns(address)
    {
        return winner;
    }
}

