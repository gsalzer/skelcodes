pragma solidity ^0.6.0;

import "./Context.sol";
import "./user.sol";


contract Pauser is Context {
    using Users for Users.User;
    Users.User private _pauser;
    
    event PasuserAdded(address indexed account);
    event PauserDeleted(address indexed account);
    
    constructor () internal {
        _addPauser(_msgSender());
    }
    
    modifier isPauser() {
        require(_pauser.exists(_msgSender()));
        _;
    }
    
    function addPauser(address account) public isPauser {
        _addPauser(account);
    }
    
    function delPauser(address account) public isPauser {
        _delPauser(account);
    }
    
    function _addPauser(address account) internal {
        _pauser.add(account);
        emit PasuserAdded(account);
    }
    
    function _delPauser(address account) internal {
        _pauser.del(account);
        emit PauserDeleted(account);
    }
}
