pragma solidity ^0.5.0;


interface IBalancerFactory {
    function isBPool(address b)
        external view returns (bool);
}

