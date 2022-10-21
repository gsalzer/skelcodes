// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./SingleAuctionV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title  Single Auction Proxy Smart Contract
/// @notice The Single Auction proxy : this is the contract that will be instancied on the blockchain. Cast this as the logic contract to interact with it.
contract SingleAuctionProxiedV1 is VCProxy, SingleAuctionHeaderV1, SingleAuctionStorageInternalV1  {

    constructor(uint256 _version, address _vc, uint256 _versionBid)  public
    VCProxy(_version, _vc) //Call the VC proxy constructor so that we know where our logic code is
    {
        versionBid = _versionBid;
    }

    //Routing the bid function to a separate smart contract than the regular version, with proper Bid ABI
    function bid(uint256 , address) external payable {

        address addr = VersionControlStoragePublic(vc).code(versionBid);
        assembly {
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



