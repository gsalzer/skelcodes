// SPDX-License-Identifier: MIT

pragma solidity ^0.6.8;

library Users {
    struct User {
        mapping (address => bool) authorizer;
    }
    
    function add(User storage admin, address account) internal {
        require(!exists(admin, account), "Admin: account has already");
        admin.authorizer[account] = true;
    }
    
    function del(User storage admin, address account) internal {
        require(exists(admin, account), "Admin: account does not authorizer");
        admin.authorizer[account] = false;
    }
    
    function exists(User storage admin, address account) internal view returns (bool) {
        require(account != address(0), "Admin: account is zero.");
        return admin.authorizer[account];
    }
}

