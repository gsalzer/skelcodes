pragma solidity ^0.4.24;

contract GandhijiMain {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract DistributeDividends {
    GandhijiMain GandhijiMainContract = GandhijiMain(0x2D0bFAe0F3E45465510F032bDD277B675DA68b29);
    
    /// @notice Any funds sent here are for dividend payment.
    function () public payable {
    }
    
    /// @notice Distribute dividends to the GandhijiMain contract. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) public {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }
            
            GandhijiMainContract.buy.value(address(this).balance)(msg.sender);
            GandhijiMainContract.exit();
        }
  }
}
