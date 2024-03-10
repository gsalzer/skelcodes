pragma solidity 0.4.24;

interface IERC1538 {
    event CommitMessage(string message);
    event FunctionUpdate(bytes4 indexed functionId, address indexed oldDelegate, address indexed newDelegate, string functionSignature);
    function updateContract(address _delegate, string _functionSignatures, string commitMessage) external;
}
