pragma solidity ^0.5.0;


import "./ERC20.sol";
import "./ERC20Detailed.sol";

/// @author The SocialChains.io Team
/// @title An ERC-20 standard complaint token associated with the SocialChains.io project.
contract Token is ERC20, ERC20Detailed {
    uint public constant ALLOCATION_FOR_COMMUNITY         = 550000000;
    uint public constant ALLOCATION_FOR_SCHOLARSHIP_FUNDS =  50000000;
    uint public constant ALLOCATION_FOR_FUNDRAISING       = 100000000;
    uint public constant ALLOCATION_FOR_EMPLOYEES         = 100000000;
    uint public constant ALLOCATION_FOR_MARKETING         =  50000000;
    uint public constant ALLOCATION_FOR_LOAN_PAYMENTS     =  50000000;
    uint public constant ALLOCATION_FOR_FOUNDERS          = 100000000;

    address public constant ACCOUNT_OF_COMMUNITY         = 0xD3e218390cA3B9Bea8e481bbFC3bd6f776972bB7;
    address public constant ACCOUNT_OF_SCHOLARSHIP_FUNDS = 0x945F5BCd6be45d334F9478223A7b7686BF7087D2;
    address public constant ACCOUNT_OF_FUNDRAISING       = 0xd6efD65C4EfC125A4A8BBF915b4A153d53c27207;
    address public constant ACCOUNT_OF_EMPLOYEES         = 0xe6876F93A3e1f3583848C1C8259BB16E482F87a3;
    address public constant ACCOUNT_OF_MARKETING         = 0x04B792640aE06d506977da2A7414fB73BC949B0e;
    address public constant ACCOUNT_OF_LOAN_PAYMENTS     = 0xf5d5B2c4aa2837dD611335D3a771Fe7AC912A84e;
    address public constant ACCOUNT_OF_FOUNDERS          = 0x55aaf05afF2cC5621aFf59C1bb03012D78e60270;
    
    
    constructor() public ERC20Detailed("SONA", "SONA", 18) {
        _mint(ACCOUNT_OF_COMMUNITY,         ALLOCATION_FOR_COMMUNITY         * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_SCHOLARSHIP_FUNDS, ALLOCATION_FOR_SCHOLARSHIP_FUNDS * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_FUNDRAISING,       ALLOCATION_FOR_FUNDRAISING       * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_EMPLOYEES,         ALLOCATION_FOR_EMPLOYEES         * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_MARKETING,         ALLOCATION_FOR_MARKETING         * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_LOAN_PAYMENTS,     ALLOCATION_FOR_LOAN_PAYMENTS     * (10 ** uint256(decimals())));
        _mint(ACCOUNT_OF_FOUNDERS,          ALLOCATION_FOR_FOUNDERS          * (10 ** uint256(decimals())));
    }
}

