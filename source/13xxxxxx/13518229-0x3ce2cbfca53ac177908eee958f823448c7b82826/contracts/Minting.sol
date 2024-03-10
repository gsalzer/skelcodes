//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./String.sol";

library MintingUtils {

    function deserializeIMXMintingBlob(bytes memory mintingBlob) internal pure returns (string memory, uint32, uint32, uint32) {
        
        string[] memory paramParts = String.split(string(mintingBlob), ",");
        require(paramParts.length == 4, "Invalid parameter count");
        
        return ( 
            paramParts[0], 
            uint32(String.toUint(paramParts[1])), 
            uint32(String.toUint(paramParts[2])), 
            uint32(String.toUint(paramParts[3])) 
        );
    }
}
