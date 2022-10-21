pragma solidity ^0.5.3;

import './Policy.sol';
import './Upgradeable.sol';

interface ITokenPlatform {
    function isITokenPlatform() external pure returns (bool);
}

contract TokenPlatform is SingleAuthorityPolicy, ITokenPlatform {
    constructor(address _authority) public {
        initSingleAuthorityPolicy(_authority);
    }

    function isITokenPlatform() external pure returns (bool) {
        return true;
    }
}

