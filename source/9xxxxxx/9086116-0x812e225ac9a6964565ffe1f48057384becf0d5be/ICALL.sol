pragma solidity 0.5.8;

interface ICALL {
    function multiPartySend(address[] calldata _toAddresses, uint256[] calldata _amounts, bytes calldata _userData) external;
    function send(address to, uint256 amount, bytes calldata data) external;
    function balanceOf(address owner) external view returns (uint256);
}

