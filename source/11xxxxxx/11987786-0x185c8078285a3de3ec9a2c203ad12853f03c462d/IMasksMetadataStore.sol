pragma solidity ^0.7.0;

interface IMasksMetadataStore {
    function getIPFSHashHexAtIndex(uint index) external view returns (bytes memory);
    function getTraitBytesAtIndex(uint index) external view returns (bytes3);
}
