// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./TheCryptographV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  TheCryptograph Proxy Smart Contract
/// @notice TheCryptograph proxy : this is this contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract TheCryptographProxiedV1 is VCProxy, TheCryptographHeaderV1, TheCryptographStorageInternalV1  {

    constructor(uint256 _version, address _vc)  public
    VCProxy(_version, _vc) //Call the VC proxy constructor so that we know where our logic code is
    {
        //Self intialize (nothing)
    }

    //No other logic code as it is all proxied

}





