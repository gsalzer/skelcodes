 library PExt {
    uint256 constant tenP18 = 1000000000000000000;
    function toWhole(uint256 n) internal pure returns(uint256){
        return n * tenP18;
    }

    //uint random_Nonce = 0;
    function getRandom(uint min, uint max, uint nonce) internal returns (uint){
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % (max-min);
        randomnumber = randomnumber + min;
        return randomnumber;
    }
}
