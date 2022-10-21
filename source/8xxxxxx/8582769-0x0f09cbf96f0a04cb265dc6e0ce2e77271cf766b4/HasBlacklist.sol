pragma solidity ^0.5.4;

contract HasBlacklist{

  mapping(address => bool) private blacklist;

  event Blacklist(address indexed addr, bool blakclisted);

  function isBlacklisted(address addr)
  public view
  returns(bool){
    return blacklist[addr];
  }

  function _addToBlacklist(address addr)
  internal{
    blacklist[addr] = true;
    emit Blacklist(addr, blacklist[addr]);
  }

  function _removeFromBlacklist(address addr)
  internal{
    blacklist[addr] = false;
    emit Blacklist(addr, blacklist[addr]);
  }
}
