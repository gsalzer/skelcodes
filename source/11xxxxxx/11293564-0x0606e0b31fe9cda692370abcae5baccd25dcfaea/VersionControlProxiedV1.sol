// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./VersionControlV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  VCProxy Proxy Smart Contract
/// @notice VCProxy proxy : this is the contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract VersionControlProxiedV1 is VCProxy, VersionControlHeaderV1, VersionControlStorageInternalV1  {

    constructor(address _vc)  public
    VCProxy(0, _vc) //Call the VC proxy constructor with 0 as index paramter
    {
        //Self initialize
        controller = msg.sender;
        code.push(_vc); //Push the address of the VC logic code at index 0
        emit VCCAddedVersion(0, _vc); //Fire relevant push event
    }

    /*
    trick to avoid infinite loop when a Version Control proxy calls itself : we override the VCProxy fallback function and
    get the address from our own array instead of stacking one more call
    */

    fallback () external payable override{
        address addr = code[version];
        assembly{
            let freememstart := mload(0x40)
            calldatacopy(freememstart, 0, calldatasize())
            let success := delegatecall(not(0), addr, freememstart, calldatasize(), freememstart, 0)
            returndatacopy(freememstart, 0, returndatasize())
            switch success
            case 0 { revert(freememstart, returndatasize()) }
            default { return(freememstart, returndatasize()) }
        }
    }
   
}



