pragma solidity 0.5.10;

/**
 * @title InterfaceProduce 
 * @dev Blob producer interface
 */
interface InterfaceProduce
{
    /**
     * @dev Initialise metadata
     * @param id The blob id
     * @return uint The generated metadata
     */
    function init(uint id) external view returns (uint);
}

