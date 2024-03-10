pragma solidity 0.4.24;

interface IERC1538Query {
    function totalFunctions() external view returns(uint256);
    function functionByIndex(uint256 _index) external view returns(string memory functionSignature, bytes4 functionId, address delegate);
    function functionExists(string _functionSignature) external view returns(bool);
    function functionSignatures() external view returns(string);
    function delegateFunctionSignatures(address _delegate) external view returns(string);
    function delegateAddress(string _functionSignature) external view returns(address);
    function functionById(bytes4 _functionId) external view returns(string signature, address delegate);
    function delegateAddresses() external view returns(address[]);
}
