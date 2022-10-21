pragma solidity ^0.5.6;


contract IManaged {

    /**
       * @dev updates managed contract address
       * @param _management address contract address
   */
    function setManagementContract(address _management) public;

    /**
       * @dev checks if address is permitted to  make an action
       * @param _subject address requested address
       * @param _permissionBit uint256 action constant value
       * @return true in case when address has a permision
   */
    function hasPermission(
        address _subject,
        uint256 _permissionBit
    )
    internal
    view
    returns (bool);

}

