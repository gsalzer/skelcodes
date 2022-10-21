// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IWhitelist {
    event Whitelisted(bytes4 indexed key);

    function addBytes4(bytes4 key) external;
    function addManyBytes4(bytes4[] memory keys) external;
    function isBytesWhitelisted(bytes memory subdomain) external view returns (bool);
}

