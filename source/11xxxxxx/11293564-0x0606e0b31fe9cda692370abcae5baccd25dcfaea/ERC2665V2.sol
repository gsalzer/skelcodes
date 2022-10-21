// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

contract ERC2665StorageInternalV2 {
    address payable internal auctionHouse;
    address internal indexCry;

    mapping(address => bool) internal isACryptograph;

    mapping(address => uint256) internal balanceOfVar;

    uint256 internal totalSupplyVar;
    mapping(uint256 => address) internal index2665ToAddress;

    mapping(address => uint256[]) internal indexedOwnership; //[Owner][index] = cryptographID
    mapping(uint256 => uint256) internal cryptographPositionInOwnershipArray; // [cryptographID] = index
    mapping(uint256 => uint256) internal lastSoldFor; //Value last sold on the cryptograph platform
    mapping(uint256 => uint256) internal transferFees; //Pending transfer fee
    mapping(uint256 => bool) internal transferFeePrepaid; //Have the next transfer fee be prepaid ?
    mapping(uint256 => address) internal approvedTransferAddress; //Address allowed to Transfer a token
    mapping(address => mapping(address => bool)) internal approvedOperator; //Approved operators mapping
	
	address internal contractWETH; // The address of the Wrapped ETH ERC-20 token accepted as payment instead of ETH

}

contract ERC2665StoragePublicV2 {
    address payable public auctionHouse;
    address public indexCry;

    mapping(address => bool) public isACryptograph;

    mapping(address => uint256) public balanceOfVar;

    uint256 public totalSupplyVar;
    mapping(uint256 => address) public index2665ToAddress;

    mapping(address => uint256[]) public indexedOwnership; //[Owner][index] = cryptographID
    mapping(uint256 => uint256) public cryptographPositionInOwnershipArray; // [cryptographID] = index
    mapping(uint256 => uint256) public lastSoldFor; // Value last sold on the cryptograph platform
    mapping(uint256 => uint256) public transferFees; // Pending transfer fee
    mapping(uint256 => bool) public transferFeePrepaid; //Have the next transfer fee be prepaid ?
    mapping(uint256 => address) public approvedTransferAddress; //Address allowed to Transfer a token
    mapping(address => mapping(address => bool)) public approvedOperator; //Approved operators mapping
	
	address public contractWETH; // The address of the Wrapped ETH ERC-20 token accepted as payment instead of ETH
}

