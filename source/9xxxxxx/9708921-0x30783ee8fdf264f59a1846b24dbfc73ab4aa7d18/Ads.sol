pragma solidity 0.4.25;
contract Ads {
string messageString = "blockchain advertising | 0xbt";
    
    function getAds() public constant returns (string) {
        return messageString;
    }
    
    function setAds (string newAds) public payable {
    messageString = newAds;
    uint256 amount = msg.value;
     {
      address(0x6b923D70078E8B1Bd4ECef4e0A70D0357044D1A4).transfer(0.002 ether);
    }
  }
    
}
