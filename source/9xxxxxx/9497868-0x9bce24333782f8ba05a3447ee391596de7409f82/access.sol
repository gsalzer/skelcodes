pragma solidity ^0.6.0;

import "./Context.sol";
import "./user.sol";

contract Access is Context{
    using Users for Users.User;
    Users.User private _authorizer;
    
    event AuthorizerAdded(address indexed account);
    event AuthorizerDeleted(address indexed account);
    
    constructor () internal {
        _addAdmin(_msgSender());
    }
    
    modifier isAuthorizer() {
        require(_authorizer.exists(_msgSender()), "Access: Caller does not Authorizer");
        _;
    }
    
    function addAdmin(address account) external isAuthorizer {
        _addAdmin(account);
    }
    
    function delAdmin(address account) external isAuthorizer {
        _delAdmin(account);
    }
    
    function _addAdmin(address account) internal {
        _authorizer.add(account);
        emit AuthorizerAdded(account);
    }
    
    function _delAdmin(address account) internal {
        _authorizer.del(account);
        emit AuthorizerDeleted(account);
    }
}


