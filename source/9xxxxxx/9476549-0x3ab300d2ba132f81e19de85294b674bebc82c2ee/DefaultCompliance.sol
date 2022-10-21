// File: contracts/compliance/ICompliance.sol

pragma solidity ^0.5.10;

interface ICompliance {
    function canTransfer(address _from, address _to, uint256 value) external view returns (bool);
}

// File: contracts/compliance/DefaultCompliance.sol

pragma solidity ^0.5.10;


contract DefaultCompliance is ICompliance {
    function canTransfer(address _from, address _to, uint256 _value) public view returns (bool) {
        return true;
    }
}
