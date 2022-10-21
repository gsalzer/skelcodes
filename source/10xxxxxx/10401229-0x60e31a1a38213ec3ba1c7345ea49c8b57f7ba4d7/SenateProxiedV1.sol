// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./SenateV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  Senate Proxy Smart Contract
/// @notice The Senate proxy : this is this contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract SenateProxiedV1 is VCProxy, SenateHeaderV1, SenateStorageInternalV1  {

    constructor(uint256 _version, address _vc)  public
    VCProxy(_version, _vc) //Call the VC proxy constructor so that we know where our logic code is
    {
        lawmaker = msg.sender; //Only the creator of this smart contract will be able to submit new addresses to be voted on
    }

    //No other logic code as it is all proxied

}



