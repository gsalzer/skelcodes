pragma solidity ^0.5.0;

contract TeamAccountInit{
    uint256 public constant INITIAL_RELEASE_COUNT = 8;
    
    struct AccountInitPlan{
        address account;
        uint256[INITIAL_RELEASE_COUNT] amounts;
        uint256[INITIAL_RELEASE_COUNT] timestamps;
    }
}

