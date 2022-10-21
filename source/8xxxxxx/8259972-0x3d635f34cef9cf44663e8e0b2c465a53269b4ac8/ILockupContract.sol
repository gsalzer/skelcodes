pragma solidity ^0.5.7;


contract ILockupContract {

    /**
    * @dev Function to lock blob amount
    * @param _address the coin holder address
    * @param _amount the coins amount to be locked
    */
    function lock(
        address _address,
        uint256 _amount
    )
    public;

    /**
    * @dev Function to unlock blob amount
    * @param _address the coin holder address
    * @param _amount the coins amount to be unlocked
    */
    function unlock(
        address _address,
        uint256 _amount
    )
    public;

    /**
    * @dev Function to check if the specified balance is allowed to transfer
    * @param _address the coin holder address
    * @param _value the coins amount to be checked
    * @param _holderBalance total holder balance
    * @return bool true in case there is enough unlocked coins
    */
    function isTransferAllowed(
        address _address,
        uint256 _value,
        uint256 _holderBalance
    )
    public
    view
    returns(bool);

    /**
    * @dev Function to get unlocked amount
    * @param _address the coin holder address
    * @param _holderBalance total holder balance
    * @return number of unlocked coins
    */
    function allowedBalance(
        address _address,
        uint256 _holderBalance
    )
    public
    view
    returns(uint256);
}

