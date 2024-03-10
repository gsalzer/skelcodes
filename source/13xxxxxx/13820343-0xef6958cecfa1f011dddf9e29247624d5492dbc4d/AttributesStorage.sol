// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract DelegateStorage {

    address public admin;

    address public pendingAdmin;

    address public attributesImplementation;

    address public pendingAttributesImplementation;

    mapping(address => bool) public controllers;
}

abstract contract AttributesStorage is DelegateStorage {

    address public _nftAddress;

    uint256 public MAX = 100000000; //100
    uint256 public MIN = 0;

    mapping(uint256 => uint256) public intelligence;
    mapping(uint256 => uint256) public agility;
    mapping(uint256 => uint256) public aggressivity;

}
