// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./CryptographKYCV1.sol";

/// @author Guillaume Gonnaud 2020
/// @title  Cryptograph KYC Proxy Smart Contract
/// @notice The proxied KYC : this is the contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract CryptographKYCProxiedV1 is VCProxy, CryptographKYCHeaderV1, CryptographKYCStorageInternalV1  {

    constructor(uint256 _version, address _vc)  public
    VCProxy(_version, _vc) //Calls the VC proxy constructor so that we know where our logic code is
    {
        //Self intialize (nothing)
    }


    //No other logic code as it is all proxied

}




