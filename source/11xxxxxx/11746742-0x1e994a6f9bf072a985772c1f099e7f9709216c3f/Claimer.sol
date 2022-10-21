pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "./GasSaver.sol";

contract Claimer is GasSaver {
    function execute(bytes[] memory claims) public {
        for (uint i = 0; i < claims.length; i++)
            address(0x1d847fB6e04437151736a53F09b6E49713A52aad).call(claims[i]);
    }

    function executeWithGasSaver(bytes[] memory claims) public discountCHI {
        execute(claims);
    }
}
