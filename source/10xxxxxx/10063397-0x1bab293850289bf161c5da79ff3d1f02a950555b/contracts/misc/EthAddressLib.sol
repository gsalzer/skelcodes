pragma solidity ^0.6.6;

library EthAddressLib {

    /**
    * @dev returns the address used within the protocol to identify ETH
    * @return the address assigned to ETH
     */
    function ethAddress() internal pure returns(address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}
