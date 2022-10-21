// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../NMWD/context.sol";

contract NMWDRoyaltyReceiver is Context{

    address immutable public nmwd;
    address immutable public artist;
    uint immutable public ptc_artist;
    mapping(address => uint) private balance;

    event Sent(address payee, uint amount);

    constructor ( address _nmwd, address _artist,  uint _ptc_artist){
        require(_ptc_artist < 10000, "Percentage too high");
        require(_ptc_artist > 0, "negative percentage");
        require(_nmwd != address(0), "adress 0 not allowed");
        require(_artist != address(0), "adress 0 not allowed");
        nmwd = _nmwd;
        artist = _artist;
        ptc_artist = _ptc_artist;
    }

    receive() external payable{
        uint amountArtist = (msg.value * ptc_artist)/10000;
        uint amountNmwd = msg.value - amountArtist;
        balance[artist] += amountArtist;
        balance[nmwd] += amountNmwd;
    }


    function withdraw(uint amount) external{

        require(amount > 0, "negative amount");
        require( _msgSender() == artist || _msgSender() == nmwd, "Not your contract");

        if(_msgSender() == artist){
            require(balance[artist] >= amount, "Not enough balance");
            balance[artist] -= amount;
            payable(artist).transfer(amount);
            emit Sent(artist, amount);

        }else if(_msgSender() == nmwd){
            require(balance[nmwd] >= amount, "Not enough balance");
            balance[nmwd] -= amount;
            payable(nmwd).transfer(amount);
            emit Sent(nmwd, amount);

        }else{
            revert();
        }
    }

    function getBalance(address _address) external view returns(uint){
        return balance[_address];
    }

}
