pragma solidity ^0.4.18;

import "./Ownable.sol";

contract BlackList is Ownable {

    function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        RemovedBlackList(_clearedUser);
    }

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

}

