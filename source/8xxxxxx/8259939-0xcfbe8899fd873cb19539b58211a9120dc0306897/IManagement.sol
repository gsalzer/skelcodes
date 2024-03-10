pragma solidity ^0.5.7;


contract IManagement {

    /**
        * @dev sets or unset permissions to make some actions
        * @param _address address Address which  is allowed/disallowed to run function
        * @param _permission uint256 constant value describes one of the permission
        * @param _value bool sets/unsets _permission
    */
    function setPermission(
        address _address,
        uint256 _permission,
        bool _value
    )
    public;

    /**
      * @dev register contract with ID
      * @param _key uint256 constant value, indicates the contract
      * @param _target address Address of the contract
    */
    function registerContract(uint256 _key, address _target) public;

    /**
     * @dev updates the percentage fee amount for dissolve request
     * @param _valueInPercentage uint256 fee amount which  should receive Platform per each dissolve
    */
    function setFeePercentage(
        uint256 _valueInPercentage
    )
    public;

    /**
      * @dev gets the fee percentage value for dissolve
      * @return uint256 the fee percentage value for dissolve
    */
    function getFeePercentage()
    public
    view
    returns (uint256);

    /**
      * @dev checks if permissions is specified for exact address
      * @return bool identifier of permissions
    */
    function permissions(address _subject, uint256 _permissionBit)
    public
    view
    returns (bool);
}

