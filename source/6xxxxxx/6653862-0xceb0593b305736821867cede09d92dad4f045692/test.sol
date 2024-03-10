pragma solidity ^0.4.21;
contract test {
    uint256 public answer;
    constructor(){
    answer = uint256(keccak256(block.blockhash(1)))%10000;
    }
}
