pragma solidity ^0.6.3;

abstract contract BrightID {
    function addContext(bytes32 context) virtual public;
    function addContextOwner(bytes32 context, address owner) virtual public;
    function addNodeToContext(bytes32 context, address nodeAddress) virtual public;
    function register(bytes32 context, bytes32[] memory cIds, uint8 v, bytes32 r, bytes32 s) virtual public;
    function removeContextOwner(bytes32 context, address owner) virtual public;
    function removeNodeToContext(bytes32 context, address nodeAddress) virtual public;
    function sponsor(bytes32 context, bytes32 contextid) virtual public;
    function isContext(bytes32 context) virtual public view returns(bool);
    function isContextOwner(bytes32 context, address owner) virtual public view returns(bool);
    function isNodeContext(bytes32 context, address nodeAddress) virtual public view returns(bool);
    function isUniqueHuman(address nodeAddress, bytes32 context) virtual public view returns(bool);
}

