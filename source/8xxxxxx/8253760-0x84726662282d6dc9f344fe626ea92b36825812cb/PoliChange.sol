pragma solidity ^0.5.1;
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function Smul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
      uint256 z = a * b;
      assert((a == 0)||(z/a == b));
      return z;
  }
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
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function Sadd(uint256 a, uint256 b) internal pure returns (uint256 c) {
      uint256 z = a + b;
      require((z >= a) && (z >= b),'Result must be greater than parameters');
      assert((z >= a) && (z >= b));
      return z;
  }
}
contract PoliPrice{
    /**
     * @dev PoliPrice corrects the USD to ETH price to all open contracts.
     */
    function readETHUSD() public view returns(uint16);
    function readUSDWEI() public view returns(uint256);
}
contract PoliToken{ 
    /**
     * @dev PoliToken used to check balanceOf Tokens and transfer tokens too.
     */
   function balanceOf(address who) public view returns (uint256);
   function transfer(address to, uint256 value) public payable returns (bool);
}
contract PoliChange{
    /**
     * @dev Here is our smartcontract that change POLI to ETH  
     */
    using SafeMath for uint256;
    address constant public cpolitokenAddress = 0x3F041a9705fd66E0E795fb1fBCA3896030F0679D; //rinkeby 0xd9dbAe6f66B3DA0FddFcDdC81A8EbE2a1c02159b; 
    address constant public cpoliPrice = 0xaf4F368061840f34e4CDeC6Ba96D0Ab6B62b632F; // rinkeby 0x7c1AB1A03402bA6Bbd2Aec6c18558b4d7B1e04eA;  
    address internal seller;
    address internal buyer; 
    bool    internal waitDeposit;
    uint internal percentGain; 
    PoliToken internal pToken;
    PoliPrice internal pPrice;
    constructor() public{
        seller = msg.sender;
        waitDeposit = true; 
        pToken = PoliToken(cpolitokenAddress); 
        pPrice = PoliPrice(cpoliPrice);
        percentGain = 0; // 1 = 1% or 20 = 20% or 200 = 200%
    }
    //Informations of contract
    function getBalanceETH() public view returns(uint){
        return address(this).balance;
    }
    function getBalancePOLI() public view returns(uint){
        return pToken.balanceOf(address(this));
    }
    function getSellerAddress() public view returns(address){
        return address(seller);
    }
    function getBuyerAddress() public view returns(address){
        return address(buyer);
    }
    function getContractAddress() public view returns(address){
        return address(this);
    }
    function getContractWEIValue() public view returns(uint){ 
        return SafeMath.Smul(getWEIGain(), getBalancePOLI()); 
    }
    function getUSDPrice() public view returns(uint){
        return pPrice.readETHUSD();
    }
    function getWEIGain() private view returns(uint){
        uint rWEIprice;
        uint gainprice;
        rWEIprice = SafeMath.Smul(1, pPrice.readUSDWEI());
        gainprice = SafeMath.Sdiv(SafeMath.Smul(rWEIprice,percentGain),100);
        return SafeMath.Sadd(rWEIprice,gainprice);
    }
    //Actions of contract
    function buyTokens() public payable chkBuy() returns(bool){
        if (getBalancePOLI() > 0){
           buyer = msg.sender;
           waitDeposit = false;
           bool ret;
           ret = pToken.transfer(buyer, pToken.balanceOf(address(this)));
           return ret; 
        }
        else{
            return false;
        }
    }
    function sellerToWithdraw() public payable isSeller() returns(bool){
        if (address(this).balance > 0){
           msg.sender.transfer(address(this).balance);
           return true;
        } 
        else{
            return false;
        }
    }
    //Functions modifiers
    modifier isSeller(){
        require(msg.sender == seller, 'Sorry, you must be the seller');
        _;
    }
    modifier isBuyer(){
        require(msg.sender == buyer, 'Sorry, you must be the buyer');
        _;
    } 
    modifier chkBuy(){
        require(waitDeposit == true, 'Sorry, This contract has already been purchased.');
        require(msg.value == getContractWEIValue(), 'You must to deposit the full value of contract. Check response of function getContractWEIValue() first');
        require(msg.sender != address(0),'Address need to be different of zero');
        _;
    }
    
}
