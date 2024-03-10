pragma solidity ^0.4.24;

interface ILuckyDraw {

    
    function add(address _plyrAddr)
        external;

    function draw()
        external
        returns (address);

    function getPlayers()
        external
        view
        returns(address[]);
    
    function getPlayersCount()
        external
        view
        returns(uint256);

    function getWinner()
        external
        view
        returns(address);
    
}

