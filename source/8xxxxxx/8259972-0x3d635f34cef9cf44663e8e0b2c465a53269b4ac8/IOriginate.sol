pragma solidity ^0.5.6;


contract IOriginate {


    /**
       * @dev Function to perform originate and mint Blobs for requester
       * @param _originateId The id of Originate request
       * @param _stableCoinAddresses coins addresses list to exchange
       * @param _maxCoinsAmount max amounts for each coin allowed to exchange
       * @return A boolean that indicates if the operation was successful.
    */
    function externalOriginate(
        uint256 _originateId,
        address[] calldata _stableCoinAddresses,
        uint256[] calldata _maxCoinsAmount
    )
    external
    returns (bool);

    /**
    * @dev Function to receive stable coin and mint blobcoins
    * @param _stableCoinAddresses The addresses of the coins that will be exchanged to originate blobs.
    * @param _values The amounts of stable coins to contribute .
    * @return A boolean that indicates if the operation was successful.
    */
    function createOriginateRequest(
        address[] memory _stableCoinAddresses,
        uint256[] memory _values
    )
    public
    returns (bool);

    /**
   * @dev Function to get total and exchanged stable coin amounts per originate request
   * @param _originateId The id of Originate request
   * @param _stableCoin stable coin address to be checked
   * @return uint256[2] array where [0] element indicates total stablecoins to be exchanged
    [1] index shows the amount of already exchanged stable coin
   */
    function getStableCoinAmountsByRequestId(
        uint256 _originateId,
        address _stableCoin
    )
    public
    view
    returns (uint256[2] memory);

    /**
      * @dev Function to perform originate and mint Blobs for requester
       * @param _originateId The id of Originate request
       * @param _stableCoinAddresses coins addresses list to exchange
       * @param _maxCoinsAmount max amounts for each coin allowed to exchange
    */
    function internalOriginate(
        uint256 _originateId,
        address[] memory _stableCoinAddresses,
        uint256[] memory _maxCoinsAmount
    )
    internal;

    /**
    * @dev Function to validate stablecoin registry and balance allowance
    * @param _stableCoinAddress stable coin address to be checked
    * @param _value stable coin amount needs to be allowed
    */
    function internalValidateCoin(
        address _stableCoinAddress,
        uint256 _value
    )
    internal;
}

