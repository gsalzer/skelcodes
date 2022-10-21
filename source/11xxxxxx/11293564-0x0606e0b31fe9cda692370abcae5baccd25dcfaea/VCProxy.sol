// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/* Based on a variation of https://blog.gnosis.pm/solidity-delegateproxy-contracts-e09957d0f201
This generic proxy is gonna ask a version control smart contract for its logic code instead
of storing the remote address himself
*/

/*
Smart contract only containing a public array named the same as VC so that the compiler call the proper
function signature in our generic proxy
*/
contract VersionControlStoragePublic {
    address[] public code;
}


/*
Storage stack of a proxy contract. VCproxy inherit this, as well as ALL logic contracts associated to a proxy for storage alignment reasons.
*/
contract VCProxyData {
    address internal vc; //Version Control Smart Contract Address
    uint256 internal version; //The index of our logic code in the Version Control array.
}


/*
Logic of a proxy contract. EVERY proxied contract inherit this
*/
contract VCProxy is VCProxyData {
    constructor(uint256 _version, address _vc) public {
        version = _version;
        vc = _vc;
    }

    fallback () virtual external payable {

        address addr = VersionControlStoragePublic(vc).code(version);
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

    
    /// @notice Generic catch-all function that refuse payments to prevent accidental Eth burn.
    receive() virtual external payable{
       require(false, "Do not send me Eth without a reason");
    }
}
