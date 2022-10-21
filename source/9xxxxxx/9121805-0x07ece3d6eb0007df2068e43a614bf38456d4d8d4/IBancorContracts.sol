pragma solidity 0.5.11;


import "./ERC20InterfaceV5.sol";

// File: contracts/converter/interfaces/IBancorConverter.sol

/*
    Bancor Converter interface
*/
contract IBancorNetwork {
    function getReturnByPath(ERC20[] calldata _path, uint256 _amount) external view returns (uint256, uint256);
    function convert2(
        ERC20[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}
