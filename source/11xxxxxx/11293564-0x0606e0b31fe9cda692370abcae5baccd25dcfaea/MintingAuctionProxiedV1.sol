// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./MintingAuctionV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  Minting Auction Proxy Smart Contract
/// @notice The Minting Auction proxy : this is this contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract MintingAuctionProxiedV1 is VCProxy, MintingAuctionHeaderV1, MintingAuctionStorageInternalV1  {

    constructor(uint256 _version, address _vc)  public
    VCProxy(_version, _vc) //Call the VC proxy constructor so that we know where our logic code is
    {
        //Self intialize (nothing)
    }

}


