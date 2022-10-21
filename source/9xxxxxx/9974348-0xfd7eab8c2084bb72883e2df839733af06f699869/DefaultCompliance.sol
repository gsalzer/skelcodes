// File: contracts/compliance/ICompliance.sol

pragma solidity ^0.6.0;

interface ICompliance {
    function canTransfer(address _from, address _to, uint256 value) external view returns (bool);
}

// File: contracts/compliance/DefaultCompliance.sol

pragma solidity ^0.6.0;


contract DefaultCompliance is ICompliance {

    /**
    * @notice checks that the transfer is compliant.
    * default compliance always returns true
    *
    * @param _from The address of the sender
    * @param _to The address of the receiver
    * @param _value The amount of tokens involved in the transfer
    */
    function canTransfer(address _from, address _to, uint256 _value) public override view returns (bool) {
        return true;
    }
}
