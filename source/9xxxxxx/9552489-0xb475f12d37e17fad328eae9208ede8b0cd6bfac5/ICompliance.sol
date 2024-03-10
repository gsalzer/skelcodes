pragma solidity ^0.4.24;

interface ICompliance {
    function mintCheck(address _investor, uint _amount) external view returns(bool result);
    function txCheck(address _from, uint256 _amount) external view returns(bool result);
}
