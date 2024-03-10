pragma solidity ^0.5.0;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}
