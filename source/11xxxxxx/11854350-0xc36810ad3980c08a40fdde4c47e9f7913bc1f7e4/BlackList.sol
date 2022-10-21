pragma solidity ^0.4.0;

import "./Ownable.sol";

contract BlackList is Ownable{

    mapping (address => bool) internal isBlackListed;
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);
    
    function getBlackListStatus(address addr) public view returns (bool) {
        return isBlackListed[addr];
    }
    
    function addBlackList (address _evilUser) public  onlyAccessorBlackFunds(msg.sender) {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }
    
    function removeBlackList (address _clearedUser) public onlyAccessorBlackFunds(msg.sender){
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }
    
    modifier onlyAccessorBlackFunds(address addr){
        require(addr == blackListAccessorAddress, "You are not allowed!");
        _;
    }

}

