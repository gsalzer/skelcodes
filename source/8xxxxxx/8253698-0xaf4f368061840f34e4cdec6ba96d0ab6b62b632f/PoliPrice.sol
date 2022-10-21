pragma solidity ^0.5.1;
library SafeMath {
/**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function Sdiv(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
          return 0;
      }
    assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
}
contract PoliPrice{
/**
  * @dev This contract was created to be used in smart contracts where price control is in USD. 
  *      The idea is change here to affect a lot of contracts.
  */
    using SafeMath for uint256;
    uint64 public constant oneEther = 1000000000000000000;
    uint16 internal usdPrice;
    address internal admin;
    //Functions Query
    function readETHUSD() public view returns(uint16){
        return usdPrice; //readETHUSD list last registered price of 1 ETHEREUM. Example: 1 ETH = 208 USD
    }
    function readUSDWEI() public view returns(uint256){
        return SafeMath.Sdiv(oneEther, usdPrice); // readUSDWEI convert 1 USD price in WEI. Example: 1 USD = 4807692307692307 wei
    }
    function readAdmin() public view returns(address){
        return admin; // readAdmin return address of administrator
    }
    //Functions Action
    function updateUSD(uint16 newPrice) public payable chkAdm() returns(bool){
        require(newPrice >= 1,'ETH price must be greater than 1 USD');
        usdPrice = newPrice;
        return true;
    }
    function withdrawDonations() public payable chkAdm() returns(bool){
        msg.sender.transfer(address(this).balance);
    }
    //Initialize
    constructor() public{
        admin = msg.sender;
        usdPrice = 208;
    }
    //Functions modifier
    modifier chkAdm(){
        require(msg.sender == admin, 'Sorry, you must to connect with administrator address');
        _;
    }
}
