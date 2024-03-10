pragma solidity ^0.5.16;

interface IProxy {
    function implementation() external view returns (address);
    function upgradeTo(string calldata _newVersion, address _newImplementation) external;
    function getImplFromVersion(string calldata _version) external view returns(address);
    function transferOwnership(address newOwner) external;
    event Upgraded(string indexed newVersion, address indexed newImplementation, string version);
}


