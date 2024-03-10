
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/utils/TokenTimelock.sol";

contract TokenLock is TokenTimelock{
    
    address public _token = 0x53C8395465A84955c95159814461466053DedEDE;
    address public _beneficiary = 0x0A605F26A5B6C37B27fdDB155CCB495fd4F128c0;
    uint256 public _releaseTime = 1689724800; // 2023-07-19 08:00:00, 北京时间
    
    constructor()  TokenTimelock(IERC20(_token), _beneficiary, _releaseTime) {
    }
}

