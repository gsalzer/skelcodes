pragma solidity ^0.5.10;

contract GasToken1 {
    function free(uint256 value) public returns (bool success);
    function freeUpTo(uint256 value) public returns (uint256 freed);
    function freeFrom(address from, uint256 value) public returns (bool success);
    function freeFromUpTo(address from, uint256 value) public returns (uint256 freed);
}

contract ERC918Interface {
  function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);
  event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
}
contract BurnGas {

    // This function consumes a lot of gas
    function expensiveStuff(address mToken, uint256 nonce, bytes32 challenge_digest) private {
        require(ERC918Interface(mToken).mint(nonce, challenge_digest), "Could not mint token");
    }

    /*
     * Frees free' tokens from the Gastoken at address gas_token'.
     * The freed tokens belong to this Example contract. The gas refund can pay
     * for up to half of the gas cost of the total transaction in which this 
     * call occurs.
     */
    function burnGasAndFree(address gas_token, uint256 free, address mToken, uint256 nonce, bytes32 challenge_digest) public {
        require(GasToken1(gas_token).free(free), "Could not free");
        expensiveStuff(mToken, nonce, challenge_digest);
    }

    /*
     * Frees free' tokens from the Gastoken at address gas_token'.
     * The freed tokens belong to the sender. The sender must have previously 
     * allowed this Example contract to free up to free' tokens on its behalf
     * (i.e., allowance(msg.sender, this)' should be at least `free').
     * The gas refund can pay for up to half of the gas cost of the total 
     * transaction in which this call occurs.
     */
    function burnGasAndFreeFrom(address gas_token, uint256 free, address mToken, uint256 nonce, bytes32 challenge_digest) public {
        require(GasToken1(gas_token).freeFrom(msg.sender, free), "Could not free");
        expensiveStuff(mToken, nonce, challenge_digest);
    }
}
