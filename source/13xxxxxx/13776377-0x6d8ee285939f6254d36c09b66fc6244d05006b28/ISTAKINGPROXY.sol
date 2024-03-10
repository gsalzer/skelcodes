interface ISTAKINGPROXY{
    /**
    * @dev a callback to perform the actual transfer of tokens to the actual staking contract 
    * Precondition: the user doing the staking MUST approve this contract or we'll revert
    **/
    function proxyTransfer(address from, uint256 amount) external;
}
