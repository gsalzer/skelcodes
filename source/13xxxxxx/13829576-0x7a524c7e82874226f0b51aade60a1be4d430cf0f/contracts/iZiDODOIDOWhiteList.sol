// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
interface IQuota {
    function getUserQuota(address user) external view returns (int);
}

contract iZiDODOIDOWhiteList is Ownable, IQuota {

    mapping(address => uint256) public userQuota;
    
    event SetQuota(address user, uint256 amount);

    function setUserQuota(address[] memory users, uint256[] memory quotas) external onlyOwner {
        require(users.length == quotas.length, "PARAMS_LENGTH_NOT_MATCH");
        for(uint256 i = 0; i< users.length; i++) {
            require(users[i] != address(0), "USER_INVALID");
            userQuota[users[i]] = quotas[i];
            // emit SetQuota(users[i],quotas[i]);
        }
    }

    function getUserQuota(address user) override external view returns (int) {
        return int(userQuota[user]);
    }
}
