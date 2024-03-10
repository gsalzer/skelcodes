pragma solidity ^0.5.7;


contract IDissolve {

    /**
      * @dev Function to perform dissolve and burn Blobs
      * @param _dissolveId The id of Dissolve request
      * @param _maxAmount of blob coins can be covered by stable coins
      * @return A boolean that indicates if the operation was successful.
   */
    function externalDissolve(
        uint256 _dissolveId,
        uint256 _maxAmount
    )
    external
    returns (bool);

    /**
    * @dev Function to get stable coins and burn blobcoins
    * @param _value The amount of blobcoins to return .
    * @return A boolean that indicates if the operation was successful.
    */
    function createDissolveRequest(uint256 _value)
    public
    returns (bool);

    /**
      * @dev Function to perform dissolve and burn Blobs
      * @param _dissolveId The id of Dissolve request
      * @param _maxAmount of blob coins can be covered by stable coins
    */
    function internalDissolve(
        uint256 _dissolveId,
        uint256 _maxAmount
    )
    internal;
}

