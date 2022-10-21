pragma solidity 0.4.26;


interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}

