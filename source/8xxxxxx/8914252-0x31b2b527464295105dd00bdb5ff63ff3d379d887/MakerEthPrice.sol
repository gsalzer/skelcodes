pragma solidity ^0.5.7;

interface oracleInterface {
    function read() external view returns (bytes32);
}

contract MakerEthPrice {
    function getEthPrice() external view returns(uint usdPerEth) {
        usdPerEth = uint(oracleInterface(0x729D19f657BD0614b4985Cf1D82531c67569197B).read());
    }
}
