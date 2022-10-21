pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./Token.sol";
import "./Exchange.sol";
import "./Lockup.sol";


contract Nabu is Ownable {
    using Math for uint256;

    event TransferReserve(address to, uint256 amount, bytes32 desc);
    event TransferTeamShare(address to, uint256 amount, bytes32 desc);

    Token public token;
    Exchange public sportsplex;
    Lockup public team;

    constructor () public {
        token = new Token();
        sportsplex = new Exchange(address(token));

        uint256 startDate = 1565013600; // Monday August 05, 2019 10:00:00 (am) in time zone America/New York (EDT)
        team = new Lockup(startDate + 550 days); // Friday February 05, 2021 09:00:00 (am) in time zone America/New York (EST)

        uint256 totalSupply = token.totalSupply();
        token.transfer(address(sportsplex), totalSupply.mul(60).div(100));
        token.transfer(address(team), totalSupply.mul(15).div(100));

        sportsplex.transferOwnership(msg.sender);
    }

    function transferReserve(address to, uint256 amount, bytes32 desc) public onlyOwner {
        token.transfer(to, amount);
        emit TransferReserve(to, amount, desc);
    }

    function transferTeamShare(address to, uint256 amount, bytes32 desc) public onlyOwner {
        team.transfer(address(token), to, amount);
        emit TransferTeamShare(to, amount, desc);
    }
}

