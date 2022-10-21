pragma solidity ^0.5.11;
interface StableTokenInterface {
    function getConvertValue(address _address) external returns(uint);
    function conversionSuccessfull(address _address) external returns(bool);
}
