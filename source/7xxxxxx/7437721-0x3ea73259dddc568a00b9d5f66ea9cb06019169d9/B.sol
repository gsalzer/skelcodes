contract B {
    function getBlock() public view returns (uint256) {
        return block.timestamp;
    }
}
