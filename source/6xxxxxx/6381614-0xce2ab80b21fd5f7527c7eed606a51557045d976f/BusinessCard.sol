pragma solidity ^0.4.24;

contract BusinessCard {
    
    address public jeremySchroeder;
    
    string public email;
    string public website;
    string public github;
    string public twitter;
    
    constructor () public {
        jeremySchroeder = msg.sender;
        email = 'jeremy.schroeder@protonmail.ch';
        website = 'https://spudz.org';
        github = 'https://github.com/spdz';
        twitter = 'https://twitter.com/_spdz';
    }
}
