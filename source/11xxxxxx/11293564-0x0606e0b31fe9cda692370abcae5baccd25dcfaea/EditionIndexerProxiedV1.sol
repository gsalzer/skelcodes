// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./EditionIndexerV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  Cryptograph Edition Indexer Proxy Smart Contract
/// @notice The proxied Edition Indexer : this is the contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract EditionIndexerProxiedV1 is VCProxy, EditionIndexerHeaderV1, EditionIndexerStorageInternalV1  {

    constructor(uint256 _version, address _vc)  public
    VCProxy(_version, _vc) //Calls the VC proxy constructor so that we know where our logic code is
    {
        //Self intialize (nothing)
    }

    //No other logic code as it is all proxied

}




