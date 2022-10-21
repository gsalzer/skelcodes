pragma solidity 0.5.17;

// @title SelfDestructingSender
// @notice Sends funds to any address using selfdestruct to bypass fallbacks.
// @dev Is invoked by the forwardETH function in the ETHForwarder contract.
contract SelfDestructingSender {
    constructor(address payable payee) public payable {
        selfdestruct(payee);
    }
}


// @title ETHForwarder
// @notice Provides a forwardETH function to allow anyone to send ETH to any address via selfdestruct
contract ETHForwarder {
    // @dev Sends msg.value ETH to payee address
    // @param payee Address that will receive the funds
    // @return address of the SelfDestructingSender contract that delivered the ETH
    function forwardETH(address payable payee) external payable returns (address) {
        return address((new SelfDestructingSender).value(msg.value)(payee));
    }
}
